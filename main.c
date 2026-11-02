#define UART (*(volatile unsigned int *)0x10000000)

static void print(const char *s) { while (*s) UART = *s++; }

int main(void) {
    print("Hello from my own RISC-V CPU!\n");
    int sum = 0;
    for (int i = 1; i <= 10; i++) sum += i;
    return (sum == 55) ? 0 : 1;
}
