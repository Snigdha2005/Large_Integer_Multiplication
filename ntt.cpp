#include <iostream>
#include <vector>
using namespace std;

const int mod = 7340033;
const int root = 5;
const int root_1 = 4404020;
const int root_pw = 1 << 20;

// Extended Euclidean Algorithm for modular inverse
int inverse(int a, int m) {
    int m0 = m, t, q;
    int x0 = 0, x1 = 1;
    if (m == 1)
        return 0;
    while (a > 1) {
        q = a / m;
        t = m;

        m = a % m, a = t;
        t = x0;

        x0 = x1 - q * x0;
        x1 = t;
    }
    if (x1 < 0)
        x1 += m0;
    return x1;
}

void fft(vector<int> & a, bool invert) {
    int n = a.size();

    for (int i = 1, j = 0; i < n; i++) {
        int bit = n >> 1;
        for (; j & bit; bit >>= 1)
            j ^= bit;
        j ^= bit;

        if (i < j)
            swap(a[i], a[j]);
    }

    for (int len = 2; len <= n; len <<= 1) {
        int wlen = invert ? root_1 : root;
        for (int i = len; i < root_pw; i <<= 1)
            wlen = (int)(1LL * wlen * wlen % mod);

        for (int i = 0; i < n; i += len) {
            int w = 1;
            for (int j = 0; j < len / 2; j++) {
                int u = a[i+j], v = (int)(1LL * a[i+j+len/2] * w % mod);
                a[i+j] = u + v < mod ? u + v : u + v - mod;
                a[i+j+len/2] = u - v >= 0 ? u - v : u - v + mod;
                w = (int)(1LL * w * wlen % mod);
            }
        }
    }

    if (invert) {
        int n_1 = inverse(n, mod);
        for (int & x : a)
            x = (int)(1LL * x * n_1 % mod);
    }
}

// Helper to convert integer to vector digits mod 10 (LSB first)
vector<int> to_digits(int x, int size) {
    vector<int> digits(size, 0);
    int i = 0;
    while (x > 0 && i < size) {
        digits[i++] = x % 10;
        x /= 10;
    }
    return digits;
}

int main() {
    int x = 1204;
    int y = 123;

    // Choose N as power of two >= 2*n_digits (for convolution)
    // Here max digits ~4 for 1204 and 3 for 123, so pick 8
    int N = 8;

    vector<int> a = to_digits(x, N);
    vector<int> b = to_digits(y, N);

    // Forward NTT
    fft(a, false);
    fft(b, false);
    
    for (int i = 0; i < N; i++) {
        cout << a[i] << " ";
    }
    cout << endl;
    for (int i = 0; i < N; i++) {
        cout << b[i] << " ";
    }
    cout << endl;
    // Point-wise multiply
    vector<int> c(N);
    for (int i = 0; i < N; i++) {
        c[i] = (int)((1LL * a[i] * b[i]) % mod);
    }

    // Inverse NTT
    fft(c, true);

    // Carry propagation to get final product digits base 10
    int carry = 0;
    for (int i = 0; i < N; i++) {
        long long val = (long long)c[i] + carry;
        c[i] = val % 10;
        carry = val / 10;
    }

    // Print result digits (LSB first)
    cout << "Result digits (LSB first): ";
    for (int i = 0; i < N; i++) cout << c[i];
    cout << endl;

    // Reverse digits to print number properly
    cout << "Result: ";
    bool started = false;
    for (int i = N-1; i >= 0; i--) {
        if (c[i] != 0) started = true;
        if (started) cout << c[i];
    }
    if (!started) cout << 0;
    cout << endl;

    cout << "Expected: " << (long long)x * y << endl;

    return 0;
}
