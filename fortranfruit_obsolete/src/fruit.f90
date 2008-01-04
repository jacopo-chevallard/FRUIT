!------------------------
! FORTRAN unit test utility
!
! Author: Andrew H. Chen chena@westinghouse.com
! Modified for use by BAI:  B. Frank, and likely others
!------------------------
!!
! Unit test framework for FORTRAN.  (FoRtran UnIT)
!
! This package is to perform unit test for FORTRAN subroutines
!
! The method used most is: call assertTrue (logical [, message])
!
!  TODO list
!    1) Make available some public variables like maybe failedAssertCount
!       Then, the test program could check this and stop with a non-zero
!       return code so Unix scripts can check on it
!    2) Maybe read some options from a "fruit.ini" type file - like the
!       maximum number of messages to allow before exiting.
!    3) Make all messages optional
!    4) Added test for all arrays
!
!
module fruit

  type testError
    integer :: status
    character (len=30) :: message
  end type testError

  integer, parameter :: MSG_LENGTH = 1000
  integer, parameter :: MSG_STACK_SIZE = 300000

  integer, private, save :: successfulAssertCount = 0
  integer, private, save :: failedAssertCount = 0
  character (len = MSG_LENGTH), private, DIMENSION (MSG_STACK_SIZE), save :: messageArray
!   This here "stack" should be turned into a linked list structure. I can do that sometime - BRF  YOYO
  integer, private, save :: messageIndex = 1

  !-------
  ! Assert true methods
  !-------
  interface assertTrue
      module procedure assertTrue_single
      module procedure assertTrue_result
      module procedure assertTrue_result_message
      module procedure assertTrue_single_message
  end interface

  interface assertEquals

      module procedure assertEqualsStringMessage

      module procedure assertEqualsLogical
      module procedure assertEqualsLogicalMessage

      module procedure assertEquals_single_int
      module procedure assertEquals_single_int_message

      module procedure assertEquals_1darray_int
      module procedure assertEquals_1darray_string
      module procedure assertEquals_1darray_int_message

      module procedure assertEquals_2darray_int
      module procedure assertEquals_2darray_int_message

      module procedure assertEquals_single_real
      module procedure assertEquals_single_real_message

      module procedure assertEquals_1darray_real
      module procedure assertEquals_1darray_real_message

      module procedure assertEquals_2darray_real

      module procedure assertEquals_single_double
      module procedure assertEquals_1darray_double
      module procedure assertEquals_2darray_double

      module procedure assertEquals_single_single_single_message
      module procedure assertEquals_spArr_spArr_int_sp_message

      module procedure assertEquals_2darray_real_message
      module procedure assertEquals_double_double_double_message
      module procedure assertEquals_single_double_message
      module procedure assertEquals_dpArr_dpArr_int_dp_message
      module procedure assertEquals_1darray_double_message
      module procedure assertEquals_2darray_double_message
      module procedure assertEquals_1darray_complex
      module procedure assertEquals_1darray_complex_message
      module procedure assertEquals_2darray_complex
      module procedure assertEquals_2darray_complex_message
  end interface

  interface assertNotEquals
      module procedure assertNotEquals_single_real
      module procedure assertNotEquals_single_double
  end interface

  interface addSuccess
    module procedure addSuccess_message
    module procedure addSuccess_UnitNameMessage
  end interface

  interface addFail
    module procedure addFail_no_message
    module procedure addFail_message
    module procedure addFail_UnitNameMessage
  end interface

  !------------
  ! Retrieve number of total cases.  Used for future report generator
  !------------
  interface getTotalCount
    module procedure getTotalCount
  end interface

  !------------
  ! Retrieve number of failed cases.  Used for future report generator
  !------------
  interface getFailedCount
    module procedure getFailedCount
  end interface

  !-------
  ! Access definition, to protect private methods
  !-------
  private :: assertTrue_single, assertTrue_result, &
    assertTrue_result_message, assertTrue_single_message, &
    addSuccess_no_message, addSuccess_message, &
    addFail_no_message, addFail_message, increaseMessageStack

contains

  ! ----
  ! Initialize all test modules
  ! ----
  subroutine initializeFruit
    successfulAssertCount = 0
    failedAssertCount = 0
    messageIndex = 1
    write (*,*)
    write (*,*) "Test module initialized"
    write (*,*)
    write (*,*) "   . : successful assert,   F : failed assert "
    write (*,*)
  end subroutine initializeFruit

  subroutine assertTrue_result (inputBoolValue, resultBoolValue)
    logical, intent (in) :: inputBoolValue
    logical, intent (out) :: resultBoolValue

    if ( inputBoolValue .eqv. .true.) then
      resultBoolValue = .true.
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      resultBoolValue = .false.
      failedAssertCount = failedAssertCount + 1
      call failedMark()
    end if

  end subroutine assertTrue_result

  subroutine assertTrue_result_message (inputBoolValue, message, resultBoolValue)
    logical, intent (in) :: inputBoolValue
    logical, intent (out) :: resultBoolValue
    character (*), intent (in) :: message

    if ( inputBoolValue .eqv. .true.) then
      resultBoolValue = .true.
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      resultBoolValue = .false.
      failedAssertCount = failedAssertCount + 1
      call failedMark()
    end if

    call increaseMessageStack(message)

  end subroutine assertTrue_result_message

  subroutine assertEqualsLogical (var1, var2)
    implicit none
    logical, intent (in)  :: var1, var2

    character(MSG_LENGTH) :: msg

    if ( var1 .EQV. var2 ) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
      call failedMark()
      write(msg, '(A, L1, A, L1)') 'Expected ', var1, ' got ', var2
      call increaseMessageStack(msg)
    end if
  end subroutine assertEqualsLogical

  subroutine assertEqualsStringMessage (var1, var2, message)
    implicit none
    character(*), intent (in)  :: var1, var2
    character (*), intent (in), optional :: message

    if ( TRIM( var1) == TRIM( var2)) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
      call failedMark()
      if (present(message)) then
        call increaseMessageStack(TRIM(message) // ' (Expected ' // TRIM(var1) // ' got ' // TRIM(var2) // ')')
      else
        call increaseMessageStack(' (Expected ' // TRIM(var1) // ' got ' // TRIM(var2) // ')')
      end if
    end if

  end subroutine assertEqualsStringMessage

  subroutine assertEqualsLogicalMessage (var1, var2, message)
    implicit none
    logical, intent (in)  :: var1, var2
    character (*), intent (in) :: message

    character(MSG_LENGTH) :: msg

    if ( var1 .EQV. var2 ) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
      call failedMark()
      write(msg, '(A, L1, A, L1)') 'Expected ', var1, ' got ', var2
      call increaseMessageStack(TRIM(message) // ' (' // TRIM(msg) // ')')
    end if
  end subroutine assertEqualsLogicalMessage

  ! ----
  ! Assert the values are true and message
  ! print error messages and return error
  ! ----
  subroutine assertTrue_single (inputBoolValue)
    implicit none
    logical, intent (in) :: inputBoolValue

    if ( inputBoolValue .eqv. .true.) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
    call failedMark()
    end if

  end subroutine assertTrue_single

  subroutine assertTrue_single_message (inputBoolValue, message)
    implicit none
    logical, intent (in) :: inputBoolValue
    character (*), intent (in) :: message

    if ( inputBoolValue .eqv. .true.) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
      call increaseMessageStack(message)
      call failedMark()
    end if
  end subroutine assertTrue_single_message

  subroutine addSuccess_message (message)
    implicit none
    character (*), intent (in), optional :: message
    successfulAssertCount = successfulAssertCount + 1
    if (present(message)) then
      call increaseMessageStack(message)
    end if
    call successfulMark()

  end subroutine addSuccess_message

  ! -----
  ! Just add one success case with message and subroutine name
  ! -----
  subroutine addSuccess_UnitNameMessage (unitName, message)
    character (*), intent (in) :: unitName
    character (*), intent (in) :: message

      call addSuccess_Message ("[in " //  unitName // "(ok)] : " //  message)

  end subroutine addSuccess_UnitNameMessage

  ! -----
  ! Just add one failed case
  ! -----
  subroutine addFail_no_message
      failedAssertCount = failedAssertCount + 1
      call failedMark()
  end subroutine addFail_no_message

  ! -----
  ! Just add one failed case
  ! -----
  subroutine addFail_message (message)
    character (*), intent (in) :: message
    failedAssertCount = failedAssertCount + 1
    call increaseMessageStack(message)
    call failedMark()
  end subroutine addFail_message

  ! -----
  ! Just add one failed case with message and subroutine name
  ! -----
  subroutine addFail_UnitNameMessage (unitName, message)
    character (*), intent (in) :: unitName
    character (*), intent (in) :: message

    call addFail_Message ("[in " //  unitName // "(fail)]: " //  message)

  end subroutine addFail_UnitNameMessage

  ! -----
  ! Just add one successful case
  ! -----
  subroutine isAllSuccessful (result)
    implicit none
      logical, intent (out) :: result
      if ( failedAssertCount > 0 ) then
        result = .false.
      else
        result = .true.
      end if

      return
  end subroutine isAllSuccessful

  ! -----
  ! Return summary of all tests in this instance
  ! -----
  subroutine getTestSummary
    implicit none

    integer :: i

    write (*,*)
    write (*,*)
    write (*,*) '    Start of FRUIT summary: '
    write (*,*)

    if (failedAssertCount > 0) then
      write (*,*) 'Some tests failed!'
    else
      write (*,*) 'SUCCESSFUL!'
    end if

    !----------------
    ! Dump message stack
    !----------------
    if ( messageIndex > 1) then
      write (*,*) '  -- Messages are:'

      DO i = 1, messageIndex - 1
        write (*,"(A)") TRIM(messageArray(i))
      end DO

      write (*,*) '  -- end of messages.'
    else
      write (*,*) '  No messages '
    end if

    if (successfulAssertCount + failedAssertCount /= 0) then

      write (*,*) 'Total test run :   ', successfulAssertCount + failedAssertCount
      write (*,*) 'Successful :       ', successfulAssertCount
      write (*,*) 'Failed :           ', failedAssertCount
      write (*,*) 'Successful rate:   ', real(successfulAssertCount) * 100.0 / real (successfulAssertCount + failedAssertCount), '%'
      write (*, *)
      write (*, *) '  -- end of FRUIT summary'

    end if

  end subroutine getTestSummary

  subroutine successfulMark
   write(*,"(A1)",ADVANCE='NO') '.'
  end subroutine successfulMark

  subroutine failedMark
   write(*,"(A1)",ADVANCE='NO') 'F'
  end subroutine failedMark

  subroutine increaseMessageStack (message)
    character(*), intent (in) :: message

    if (messageIndex > MSG_STACK_SIZE ) then
      write (*, *) "Too many errors to put into stack"
      call getTestSummary ()
      stop 1
    end if

    messageArray (messageIndex) = message
    messageIndex = messageIndex + 1
  end subroutine increaseMessageStack

  subroutine assertEquals_single_int (var1, var2)
    implicit none
    integer, intent (in) :: var1, var2

    if ( var1 .eq. var2) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
      call failedMark()
    end if

  end subroutine assertEquals_single_int

  subroutine assertEquals_1darray_int (var1, var2, n)
    implicit none
    integer, intent (in) :: n
    integer, intent (in) :: var1(n), var2(n)

    integer count

    loop_dim1: do count = 1, n
       if ( var1(count) .ne. var2(count)) then
         failedAssertCount = failedAssertCount + 1
         call failedMark()
         exit loop_dim1
       end if
    end do loop_dim1

    if (count > n) then
       successfulAssertCount = successfulAssertCount + 1
       call successfulMark()
    endif

  end subroutine assertEquals_1darray_int

  subroutine assertEquals_2darray_int (var1, var2, n, m)
    implicit none
    integer, intent (in) :: n, m
    integer, intent (in) :: var1(n,m), var2(n,m)

    integer count1, count2

    loop_dim2: do count2 = 1, m
       loop_dim1: do count1 = 1, n
          if ( var1(count1,count2) .ne. var2(count1,count2)) then
            failedAssertCount = failedAssertCount + 1
            call failedMark()
            exit loop_dim2
          end if
       end do loop_dim1
    end do loop_dim2

    if ((count2 > m) .and. (count1 > n)) then
       successfulAssertCount = successfulAssertCount + 1
       call successfulMark()
    endif

  end subroutine assertEquals_2darray_int

  subroutine assertEquals_single_real (var1, var2)
    implicit none
    real, intent (in) :: var1, var2

    if ( var1 .eq. var2) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
      call failedMark()
    end if
  end subroutine assertEquals_single_real

  subroutine assertNotEquals_single_real (var1, var2)
    implicit none
    real, intent (in) :: var1, var2

    if ( var1 .ne. var2) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
      call failedMark()
    end if

  end subroutine assertNotEquals_single_real

  subroutine assertNotEquals_1darray_real (var1, var2, n)
    implicit none
    integer, intent (in) :: n
    real, intent (in) :: var1(n), var2(n)

    integer count

    loop_dim1: do count = 1, n
       if ( var1(count) .ne. var2(count)) then
         failedAssertCount = failedAssertCount + 1
         call failedMark()
         exit loop_dim1
       end if
    end do loop_dim1

    if (count > n) then
       successfulAssertCount = successfulAssertCount + 1
       call successfulMark()
    endif

  end subroutine assertNotEquals_1darray_real

  subroutine assertEquals_2darray_real (var1, var2, n, m)
    implicit none
    integer, intent (in) :: n, m
    real, intent (in) :: var1(n,m), var2(n,m)

    integer count1, count2

    loop_dim2: do count2 = 1, m
       loop_dim1: do count1 = 1, n
          if ( var1(count1,count2) .ne. var2(count1,count2)) then
            failedAssertCount = failedAssertCount + 1
            call failedMark()
            exit loop_dim2
          end if
       end do loop_dim1
    end do loop_dim2

    if ((count2 > m) .and. (count1 > n)) then
       successfulAssertCount = successfulAssertCount + 1
       call successfulMark()
    endif

  end subroutine assertEquals_2darray_real

  subroutine assertEquals_single_single_single_message(var1, var2, var3, message)
    implicit none
    real, intent (in) :: var1, var2, var3
    character(*), intent( in) :: message

    if ( abs( var1 - var2) .le. var3) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
      call failedMark()
      write(*,*) message   !YOYO, is there a better place to put this string?
    end if

  end subroutine assertEquals_single_single_single_message

  ! ----
  ! Assert the single precision arrays are equal within a tolerance
  ! print error messages and return error
  ! ----
  subroutine assertEquals_spArr_spArr_int_sp_message(var1, var2, n, var3, message)
    implicit none
    integer, intent(in) :: n
    real, intent (in) :: var1(n), var2(n), var3
    character(*), intent( in) :: message

    if ( maxval( abs( var1 - var2)) .le. var3) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
      call failedMark()
      write(*,*) message   !YOYO, is there a better place to put this string?
    end if

  end subroutine assertEquals_spArr_spArr_int_sp_message

  ! ----
  ! Assert the double precision arrays are equal within a tolerance
  ! print error messages and return error
  ! ----
  subroutine assertEquals_dpArr_dpArr_int_dp_message(var1, var2, n, var3, message)
    implicit none
    integer, intent(in) :: n
    double precision, intent (in) :: var1(n), var2(n), var3
    character(*), intent( in) :: message

    if ( maxval( abs( var1 - var2)) .le. var3) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
      call failedMark()
      write(*,*) message   !YOYO, is there a better place to put this string?
    end if

  end subroutine assertEquals_dpArr_dpArr_int_dp_message

  subroutine assertEquals_double_double_double_message(var1, var2, var3, message)
    implicit none
    double precision, intent (in) :: var1, var2, var3
    character(*), intent( in) :: message

    if ( abs( var1 - var2) .le. var3) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
      call failedMark()
      write(*,*) message   !YOYO, is there a better place to put this string?
    end if

  end subroutine assertEquals_double_double_double_message

  subroutine assertEquals_single_double (var1, var2)
    implicit none
    double precision, intent (in) :: var1, var2

    if ( var1 .eq. var2) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
      call failedMark()
    end if

  end subroutine assertEquals_single_double

  subroutine assertNotEquals_single_double (var1, var2)
    implicit none
    double precision, intent (in) :: var1, var2

    if ( var1 .ne. var2) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
      call failedMark()
    end if

  end subroutine assertNotEquals_single_double

  ! ----
  ! Assert the double precision 1-D arrays are equal
  ! print error messages and return error
  ! ----
  subroutine assertEquals_1darray_double (var1, var2, n)
    implicit none
    integer, intent (in) :: n
    double precision, intent (in) :: var1(n), var2(n)

    integer count

    loop_dim1: do count = 1, n
       if ( var1(count) .ne. var2(count)) then
         failedAssertCount = failedAssertCount + 1
         call failedMark()
         exit loop_dim1
       end if
    end do loop_dim1

    if (count > n) then
       successfulAssertCount = successfulAssertCount + 1
       call successfulMark()
    endif

  end subroutine assertEquals_1darray_double

  subroutine assertEquals_2darray_double (var1, var2, n, m)
    implicit none
    integer, intent (in) :: n, m
    double precision, intent (in) :: var1(n,m), var2(n,m)

    integer count1, count2

    loop_dim2: do count2 = 1, m
       loop_dim1: do count1 = 1, n
          if ( var1(count1,count2) .ne. var2(count1,count2)) then
            failedAssertCount = failedAssertCount + 1
            call failedMark()
            exit loop_dim2
          end if
       end do loop_dim1
    end do loop_dim2

    if ((count2 > m) .and. (count1 > n)) then
       successfulAssertCount = successfulAssertCount + 1
       call successfulMark()
    endif

  end subroutine assertEquals_2darray_double

  ! ----
  ! Assert the integer values are equal
  ! print error messages and return error
  ! ----
  subroutine assertEquals_single_int_message (var1, var2, message)
    implicit none
    integer, intent (in) :: var1, var2
    character (*), intent (in) :: message

    if ( var1 .eq. var2) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
      call increaseMessageStack(message)
      call failedMark()
    end if

  end subroutine assertEquals_single_int_message

  subroutine assertEquals_1darray_int_message (var1, var2, n, message)
    implicit none
    integer, intent (in) :: n
    integer, intent (in) :: var1(n), var2(n)
    character (*), intent (in) :: message

    integer count

    loop_dim1: do count = 1, n
       if ( var1(count) .ne. var2(count)) then
         failedAssertCount = failedAssertCount + 1
         call increaseMessageStack(message)
         call failedMark()
         return
       end if
    end do loop_dim1

    successfulAssertCount = successfulAssertCount + 1
    call successfulMark()
  end subroutine assertEquals_1darray_int_message

  subroutine assertEquals_1darray_string (var1, var2, n, message)
    implicit none
    integer, intent (in) :: n
    character(*), intent (in) :: var1(n), var2(n)
    character (*), intent (in), optional :: message
    character(len=200) :: msg

    integer count

    loop_dim1: do count = 1, n
       if ( trim(var1(count)) .ne. trim(var2(count))) then
         failedAssertCount = failedAssertCount + 1
         if (present(message)) then
           call increaseMessageStack(message)
         end if

         write (msg,1000) count
         1000  format(I5)

         msg = 'error at count: ' // trim(msg)  
         msg = msg // 'first value: ' // trim(var1(count))
         msg = msg // 'second value: ' // trim(var2(count))

         call increaseMessageStack(msg)
         call failedMark()
         return
       end if
    end do loop_dim1

    successfulAssertCount = successfulAssertCount + 1
    call successfulMark()
  end subroutine assertEquals_1darray_string

  subroutine assertEquals_2darray_int_message (var1, var2, n, m, message)
    implicit none
    integer, intent (in) :: n, m
    integer, intent (in) :: var1(n,m), var2(n,m)
    character (*), intent (in) :: message

    integer count1, count2

    loop_dim2: do count2 = 1, m
       loop_dim1: do count1 = 1, n
          if ( var1(count1,count2) .ne. var2(count1,count2)) then
            failedAssertCount = failedAssertCount + 1
            call increaseMessageStack(message)
            call failedMark()
            return
          end if
       end do loop_dim1
    end do loop_dim2

    successfulAssertCount = successfulAssertCount + 1
    call successfulMark()

  end subroutine assertEquals_2darray_int_message

  subroutine assertEquals_single_real_message (var1, var2, message)
    implicit none
    real, intent (in) :: var1, var2
    character (*), intent (in) :: message

    if ( var1 .eq. var2) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
      call increaseMessageStack(message)
      call failedMark()
    end if

  end subroutine assertEquals_single_real_message

  subroutine assertEquals_1darray_real (var1, var2, n)
    implicit none
    integer, intent (in) :: n
    real, intent (in) :: var1(n), var2(n)

    integer count

    loop_dim1: do count = 1, n
      if ( var1(count) .ne. var2(count)) then
        failedAssertCount = failedAssertCount + 1
        call failedMark()
        exit loop_dim1
      end if
    end do loop_dim1

    if (count > n) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    endif

  end subroutine assertEquals_1darray_real

  subroutine assertEquals_1darray_real_message (var1, var2, n, message)
    implicit none
    integer, intent (in) :: n
    real, intent (in) :: var1(n), var2(n)
    character (*), intent (in) :: message

    integer count

    loop_dim1: do count = 1, n
       if ( var1(count) .ne. var2(count)) then
         failedAssertCount = failedAssertCount + 1
         call increaseMessageStack(message)
         call failedMark()
         exit loop_dim1
       end if
    end do loop_dim1

    if (count > n) then
       successfulAssertCount = successfulAssertCount + 1
       call successfulMark()
    endif

  end subroutine assertEquals_1darray_real_message

  subroutine assertEquals_2darray_real_message (var1, var2, n, m, message)
    implicit none
    integer, intent (in) :: n, m
    real, intent (in) :: var1(n,m), var2(n,m)
    character (*), intent (in) :: message

    integer count1, count2

    loop_dim2: do count2 = 1, m
       loop_dim1: do count1 = 1, n
          if ( var1(count1,count2) .ne. var2(count1,count2)) then
            failedAssertCount = failedAssertCount + 1
            call increaseMessageStack(message)
            call failedMark()
            exit loop_dim2
          end if
       end do loop_dim1
    end do loop_dim2

    if ((count2 > m) .and. (count1 > n)) then
       successfulAssertCount = successfulAssertCount + 1
       call successfulMark()
    endif

  end subroutine assertEquals_2darray_real_message

  ! ----
  ! Assert the double precision values are equal
  ! print error messages and return error
  ! ----
  subroutine assertEquals_single_double_message (var1, var2, message)
    implicit none
    double precision, intent (in) :: var1, var2
    character (*), intent (in) :: message

    if ( var1 .eq. var2) then
      successfulAssertCount = successfulAssertCount + 1
      call successfulMark()
    else
      failedAssertCount = failedAssertCount + 1
      call increaseMessageStack(message)
      call failedMark()
    end if

  end subroutine assertEquals_single_double_message

  subroutine assertEquals_1darray_double_message (var1, var2, n, message)
    implicit none
    integer, intent (in) :: n
    double precision, intent (in) :: var1(n), var2(n)
    character (*), intent (in) :: message

    integer count

    loop_dim1: do count = 1, n
       if ( var1(count) .ne. var2(count)) then
         failedAssertCount = failedAssertCount + 1
         call increaseMessageStack(message)
         call failedMark()
         exit loop_dim1
       end if
    end do loop_dim1

    if (count > n) then
       successfulAssertCount = successfulAssertCount + 1
       call successfulMark()
    endif

  end subroutine assertEquals_1darray_double_message

  subroutine assertEquals_2darray_double_message (var1, var2, n, m, message)
    implicit none
    integer, intent (in) :: n, m
    double precision, intent (in) :: var1(n,m), var2(n,m)
    character (*), intent (in) :: message

    integer count1, count2

    loop_dim2: do count2 = 1, m
       loop_dim1: do count1 = 1, n
          if ( var1(count1,count2) .ne. var2(count1,count2)) then
            failedAssertCount = failedAssertCount + 1
            call increaseMessageStack(message)
            call failedMark()
            exit loop_dim2
          end if
       end do loop_dim1
    end do loop_dim2

    if ((count2 > m) .and. (count1 > n)) then
       successfulAssertCount = successfulAssertCount + 1
       call successfulMark()
    endif

  end subroutine assertEquals_2darray_double_message

  SUBROUTINE assertEquals_1darray_complex (var1, var2, n)
    IMPLICIT NONE
    INTEGER,          INTENT(IN) :: n
    DOUBLE COMPLEX,   INTENT(IN) :: var1(n), var2(n)

    INTEGER count

    loop_dim1: DO count = 1, n
       IF ( var1(count) .NE. var2(count)) THEN
         failedAssertCount = failedAssertCount + 1
         CALL failedMark()
         EXIT loop_dim1
       END IF
    ENDDO loop_dim1

    IF (count > n) THEN
       successfulAssertCount = successfulAssertCount + 1
       CALL successfulMark()
    ENDIF

  END SUBROUTINE assertEquals_1darray_complex

  SUBROUTINE assertEquals_1darray_complex_message (var1, var2, n, message)
    IMPLICIT NONE
    INTEGER,          INTENT(IN) :: n
    DOUBLE COMPLEX,   INTENT(IN) :: var1(n), var2(n)
    CHARACTER (*),    INTENT(IN) :: message

    INTEGER count

    loop_dim1: DO count = 1, n
       IF ( var1(count) .NE. var2(count)) THEN
         failedAssertCount = failedAssertCount + 1
         CALL increaseMessageStack(message)
         CALL failedMark()
         EXIT loop_dim1
       END IF
    ENDDO loop_dim1

    IF (count > n) THEN
       successfulAssertCount = successfulAssertCount + 1
       CALL successfulMark()
    ENDIF

  END SUBROUTINE assertEquals_1darray_complex_message

  SUBROUTINE assertEquals_2darray_complex (var1, var2, n, m)
    IMPLICIT NONE
    INTEGER,        INTENT(IN) :: n, m
    DOUBLE COMPLEX, INTENT(IN) :: var1(n,m), var2(n,m)

    INTEGER count1, count2

    loop_dim2: DO count2 = 1, m
       loop_dim1: DO count1 = 1, n
          IF ( var1(count1,count2) .ne. var2(count1,count2)) THEN
            failedAssertCount = failedAssertCount + 1
            CALL failedMark()
            EXIT loop_dim2
          ENDIF
       ENDDO loop_dim1
    ENDDO loop_dim2

    IF ((count2 > m) .AND. (count1 > n)) THEN
       successfulAssertCount = successfulAssertCount + 1
       CALL successfulMark()
    ENDIF

  END SUBROUTINE assertEquals_2darray_complex

  SUBROUTINE assertEquals_2darray_complex_message (var1, var2, n, m, message)
    IMPLICIT NONE
    INTEGER,          INTENT(IN) :: n, m
    DOUBLE COMPLEX,   INTENT(IN) :: var1(n,m), var2(n,m)
    CHARACTER (*),    INTENT(IN) :: message

    INTEGER count1, count2

    loop_dim2: DO count2 = 1, m
       loop_dim1: DO count1 = 1, n
          IF ( var1(count1,count2) .ne. var2(count1,count2)) THEN
            failedAssertCount = failedAssertCount + 1
            CALL increaseMessageStack(message)
            CALL failedMark()
            EXIT loop_dim2
          ENDIF
       ENDDO loop_dim1
    ENDDO loop_dim2

    IF ((count2 > m) .AND. (count1 > n)) THEN
       successfulAssertCount = successfulAssertCount + 1
       CALL successfulMark()
    ENDIF

  END SUBROUTINE assertEquals_2darray_complex_message

  subroutine getTotalCount (count)
  implicit none
    integer, intent (out) :: count

    count = successfulAssertCount + failedAssertCount

  end subroutine getTotalCount

  subroutine getFailedCount (count)
  implicit none
    integer, intent (out) :: count

    count = failedAssertCount

  end subroutine getFailedCount

END module fruit