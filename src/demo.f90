! GRAPE-3 Fortran client smoke test. This is NOT Steinmetz's GRAPESPH code.
program grape3_demo
    use iso_fortran_env, only: real64
    implicit none
    integer, parameter :: np = 3, ni = 2
    integer :: i, k, chips, unique_n, nfound, output_unit, stat
    integer :: list(np), expected_list(2)
    integer, external :: g3nchips, g3readnbl, g3getnbl
    real(real64) :: x(3,np), m(np), a(3,ni), pot(ni), expected_a(3,ni), expected_pot(ni)
    real(real64) :: h_sq, eps_sq, scales
    character(len=512) :: output_path

    x = reshape([0d0, 0d0, 0d0, &
                 1d0, 0d0, 0d0, &
                 0d0, 2d0, 0d0], shape(x))
    m = [1d0, 2d0, 3d0]
    scales = 0.001d0
    eps_sq = 0.25d0
    h_sq = 1.21d0

    call g3init()
    chips = g3nchips()
    if (chips < ni) error stop 'not enough GRAPE chips'
    call g3setscales(scales, scales)
    call g3seteps2(eps_sq)
    call g3setn(np)
    do i = 1, np
        call g3setxj(i-1, x(:,i))
        call g3setmj(i-1, m(i))
    end do
    do i = 1, ni
        call g3seth2(h_sq, i-1)
    end do
    call g3frc(x(:,1:ni), a, pot, ni)

    unique_n = g3readnbl(0)
    if (unique_n /= 2) error stop 'distinct neighbour union should contain two particles'
    expected_list = [1, 0] ! C interface indices are zero-based, descending.
    do i = 1, ni
        list = -1
        nfound = g3getnbl(i-1, list)
        if (nfound /= 2) error stop 'wrong neighbour count'
        if (any(list(1:2) /= expected_list)) error stop 'wrong neighbour list'
    end do

    expected_a = 0d0
    expected_pot = 0d0
    do i = 1, ni
        do k = 1, np
            call reference_pair(x(:,i), x(:,k), m(k), eps_sq, expected_a(:,i), expected_pot(i))
        end do
    end do
    if (maxval(abs(a-expected_a)) > 1d-12) error stop 'gravity acceleration mismatch'
    if (maxval(abs(pot-expected_pot)) > 1d-12) error stop 'potential mismatch'

    output_path = 'results/demo.csv'
    call get_command_argument(1, output_path, status=stat)
    if (stat /= 0 .or. len_trim(output_path) == 0) output_path = 'results/demo.csv'
    open(newunit=output_unit, file=trim(output_path), status='replace', action='write', iostat=stat)
    if (stat /= 0) error stop 'output path cannot be opened (create its parent directory first)'
    write(output_unit,'(a)') 'index,x,y,z,ax,ay,az,potential,neighbours'
    do i = 1, ni
        write(output_unit,'(i0,7(",",es24.16),",",i0)') i-1, x(:,i), a(:,i), pot(i), 2
    end do
    close(output_unit)
    call g3free()
    print '(a)', 'PASS: Fortran GRAPE-3 ABI, direct-summation forces, and neighbours'
    print '(a,a)', 'Output: ', trim(output_path)

contains
    subroutine reference_pair(xi,xj,mass,soft2,acc_i,phi_i)
        real(real64), intent(in) :: xi(3), xj(3), mass, soft2
        real(real64), intent(inout) :: acc_i(3), phi_i
        real(real64) :: r(3), r2, inv
        r = xj - xi
        r2 = sum(r*r)
        if (r2 <= 0d0) return
        inv = 1d0 / sqrt(r2 + soft2)
        acc_i = acc_i + mass * r * inv**3
        phi_i = phi_i - mass * inv
    end subroutine
end program
