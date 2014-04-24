module SrcSink_Sandbox_module

  use SrcSink_Sandbox_Base_class
  use SrcSink_Sandbox_WIPP_Gas_class
  
  use PFLOTRAN_Constants_module

  implicit none
  
  private
  
#include "finclude/petscsys.h"

  class(srcsink_sandbox_base_type), pointer, public :: sandbox_list

  interface SSSandboxRead
    module procedure SSSandboxRead1
    module procedure SSSandboxRead2
  end interface
  
  interface SSSandboxDestroy
    module procedure SSSandboxDestroy1
    module procedure SSSandboxDestroy2
  end interface
  
  public :: SSSandboxInit, &
            SSSandboxRead, &
            SSSandboxSetup, &
            SSSandbox, &
            SSSandboxDestroy

contains

! ************************************************************************** !

subroutine SSSandboxInit(option)
  ! 
  ! Initializes the sandbox list
  ! 
  ! Author: Glenn Hammond
  ! Date: 04/11/14
  ! 
  use Option_module
  implicit none
  type(option_type) :: option

  if (associated(sandbox_list)) then
    call SSSandboxDestroy()
  endif
  nullify(sandbox_list)

end subroutine SSSandboxInit

! ************************************************************************** !

subroutine SSSandboxSetup(option)
  ! 
  ! Calls all the initialization routines for all source/sinks in
  ! the sandbox list
  ! 
  ! Author: Glenn Hammond
  ! Date: 04/11/14
  ! 

  use Option_module
  
  implicit none
  
  type(option_type) :: option
  
  class(srcsink_sandbox_base_type), pointer :: cur_sandbox  

  ! sandbox source/sinks
  cur_sandbox => sandbox_list
  do
    if (.not.associated(cur_sandbox)) exit
    call cur_sandbox%Setup(option)
    cur_sandbox => cur_sandbox%next
  enddo 

end subroutine SSSandboxSetup

! ************************************************************************** !

subroutine SSSandboxRead1(input,option)
  ! 
  ! Reads input deck for source/sink sandbox parameters
  ! 
  ! Author: Glenn Hammond
  ! Date: 04/11/14
  ! 

  use Option_module
  use String_module
  use Input_Aux_module
  use Utility_module
  
  implicit none
  
  type(input_type) :: input
  type(option_type) :: option

  call SSSandboxRead(sandbox_list,input,option)

end subroutine SSSandboxRead1

! ************************************************************************** !

subroutine SSSandboxRead2(local_sandbox_list,input,option)
  ! 
  ! Reads input deck for src/sink sandbox parameters
  ! 
  ! Author: Glenn Hammond
  ! Date: 04/11/14
  ! 

  use Option_module
  use String_module
  use Input_Aux_module
  use Utility_module
  
  implicit none
  
  class(srcsink_sandbox_base_type), pointer :: local_sandbox_list  
  type(input_type) :: input
  type(option_type) :: option

  character(len=MAXSTRINGLENGTH) :: string
  character(len=MAXWORDLENGTH) :: word
  class(srcsink_sandbox_base_type), pointer :: new_sandbox, cur_sandbox
  
  nullify(new_sandbox)
  do 
    call InputReadPflotranString(input,option)
    if (InputError(input)) exit
    if (InputCheckExit(input,option)) exit

    call InputReadWord(input,option,word,PETSC_TRUE)
    call InputErrorMsg(input,option,'keyword','CHEMISTRY,REACTION_SANDBOX')
    call StringToUpper(word)   

    select case(trim(word))
      case('WIPP-GAS_GENERATION')
        new_sandbox => WIPPGasGenerationCreate()
      case default
        option%io_buffer = 'SRCSINK_SANDBOX keyword: ' // &
          trim(word) // ' not recognized.'
        call printErrMsg(option)
    end select
    
    call new_sandbox%ReadInput(input,option)
    
    if (.not.associated(local_sandbox_list)) then
      local_sandbox_list => new_sandbox
    else
      cur_sandbox => local_sandbox_list
      do
        if (.not.associated(cur_sandbox%next)) exit
        cur_sandbox => cur_sandbox%next
      enddo
      cur_sandbox%next => new_sandbox
    endif
  enddo
  
end subroutine SSSandboxRead2

! ************************************************************************** !

subroutine SSSandbox(Residual,Jacobian,compute_derivative,material_auxvar, &
                     option)
  ! 
  ! Evaluates source/sink term storing residual and/or Jacobian
  ! 
  ! Author: Glenn Hammond
  ! Date: 04/11/14
  ! 

  use Option_module
  use Material_Aux_class, only: material_auxvar_type
  
  implicit none

  type(option_type) :: option
  PetscBool :: compute_derivative
  PetscReal :: Residual(option%nflowdof)
  PetscReal :: Jacobian(option%nflowdof,option%nflowdof)
  PetscReal :: porosity
  PetscReal :: volume
  class(material_auxvar_type) :: material_auxvar
  
  class(srcsink_sandbox_base_type), pointer :: cur_srcsink
  
  cur_srcsink => sandbox_list
  do
    if (.not.associated(cur_srcsink)) exit
      call cur_srcsink%Evaluate(Residual,Jacobian,compute_derivative, &
                                material_auxvar,option)
    cur_srcsink => cur_srcsink%next
  enddo

end subroutine SSSandbox

! ************************************************************************** !

subroutine SSSandboxDestroy1()
  ! 
  ! Destroys master sandbox list
  ! 
  ! Author: Glenn Hammond
  ! Date: 04/11/14
  ! 

  implicit none

  call SSSandboxDestroy(sandbox_list)
  
end subroutine SSSandboxDestroy1

! ************************************************************************** !

subroutine SSSandboxDestroy2(local_sandbox_list)
  ! 
  ! Destroys arbitrary sandbox list
  ! 
  ! Author: Glenn Hammond
  ! Date: 04/11/14
  ! 

  implicit none

  class(srcsink_sandbox_base_type), pointer :: local_sandbox_list

  class(srcsink_sandbox_base_type), pointer :: cur_sandbox, prev_sandbox
  
  ! sandbox source/sinks
  cur_sandbox => local_sandbox_list
  do
    if (.not.associated(cur_sandbox)) exit
    prev_sandbox => cur_sandbox%next
    call cur_sandbox%Destroy()
    deallocate(cur_sandbox)
    cur_sandbox => prev_sandbox
  enddo  

end subroutine SSSandboxDestroy2

end module SrcSink_Sandbox_module