module slice_assign @test;

fn void assign_slice()
{
	int[8] a;
	a[2..3] = { 1, 2 }[..];
	a[5..7] = 5;
	assert(a == (int[8]){ 0, 0, 1, 2, 0, 5, 5, 5});
}