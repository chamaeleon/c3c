module std::math::vector;
alias Vec2f = float[<2>];

module abc;
import std::math;
alias Vec2f @weak = std::math::vector::Vec2f;
fn Vec2f foo(Vec2f a) { return a * 2; }

module gog;
import std::math;
alias Vec2f @weak = std::math::vector::Vec2f;

module deef;
import gog;

alias Vec2f @weak = gog::Vec2f;
fn Vec2f foo(Vec2f a) { return a * 2; }

module test;
import abc;
import std::math;
fn void test()
{
	Vec2f a;
	abc::foo(a);
}

module test2;
import abc;
import deef;
fn void test2()
{
	Vec2f a;
	abc::foo(a);
}