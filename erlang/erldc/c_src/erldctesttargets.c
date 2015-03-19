/*
  Copyright (c) 2014 Erik Mackdanz <erikmack@gmail.com>

  Permission to use, copy, modify, and distribute this software for any
  purpose with or without fee is hereby granted, provided that the above
  copyright notice and this permission notice appear in all copies.

  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.          
*/

#include <stdlib.h>
#include <stdio.h>

char get_next_char(char in) {
  return in+1;
}

unsigned char get_next_char_u(unsigned char in) {
  /* printf("In c, sum is %d\n",in+1); */
  return in+1;
}

int is_false(int in) {
  return !in;
}

unsigned int dual_increment_u(unsigned int in) {
  in++;
  in++;
  return in;
}

short times_three(short in) {
  return in * 3;
}

unsigned short times_three_u(unsigned short in) {
  return in * 3;
}

long add_nineteen(long in) {
  return in + 19;
}

unsigned long add_nineteen_u(unsigned long in) {
  return in + 19;
}

long long subtract_four(long long in) {
  return in - 4;
}

unsigned long long subtract_four_u(unsigned long long in) {
  return in - 4;
}

int add_seven(int in) {
  return in + 7;
}

int add_one(int in) {
  return in + 1;
}

void* coolmalloc(int sz) {
  void* ptr = malloc(sz);
  /* printf("I've allocated at addr %p\n",ptr); */
  return ptr;
}

void* coolidentity(void* in) {
  return in;
}

void coolsetstr(void* buf, char* val) {
  sprintf(buf,"%s",val);
}

void coolfree(void* ptr) {
  /* printf("The value to free is %s\n", ptr); */
  free(ptr);
}

void noop() {}

float calculate_pi(float precision) {
  return 21.0 / (7.0 * precision); // closer...
}

double times_pi(double multiplicand) {
  return multiplicand * 3.1; // nerd rage!
}

char* interested_reply(char* yourname) {
  int totalmax = 256;
  char* buf = malloc(totalmax);
  snprintf(buf,totalmax,"Really, %s?  My name is Erik.",yourname);
  return buf;
}

char* several_args(long one, char two, char* three, float four) {
  char* reply = malloc(100);
  snprintf(reply, 100,"Your args were %ld, %c, %s, %.1f",
           one,two,three,four);
  return reply;
}
