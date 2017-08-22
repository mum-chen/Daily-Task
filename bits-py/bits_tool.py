try:
    from enum import Enum
except:
    from aenum import Enum

class Bits(object):
    class Type(Enum):
        b = 2
        B = 2
        bin = 2
        BIN = 2
        d = 10
        D = 10
        dec = 10
        DEC = 10
        h = 16
        H = 16
        hex = 16
        HEX = 16

    base_list = (2, 10, 16)

    class UnkonwnBase(Exception):
        pass

    @staticmethod
    def int2bin(n, bits = None):
        n = int(str(n))
        res = ""
        while n:
            bit = str(n & 1)
            res = bit + res
            n >>= 1

        if bits and len(res) < bits:
            res = "0" * (len(res) - bits) + res
        return res

    @classmethod
    def calc_bits_len(cls, n, step = 16):
        return step + ((not not n >> step).real and cls.calc_bits_len(n >> step, step))

    def __init__(self, data = 0, base = 16, bits = None):
        data = int(str(data), base)
        bits = bits or self.calc_bits_len(data, 16)
        self.__data = self.int2bin(data, bits)

    def __getitem__(self, n):
        if isinstance(n, int):
            if len(self.__data) <= n:
                return 0
            else:
                return self.__data[n]

        if isinstance(n, slice):
            start = n.start or 0
            stop = n.stop or len(self.__data)
            base = n.step or 2

            data = self.__data[start:stop]
            if base not in self.base_list:
                raise self.UnkonwnBase

            key = {2:"bin", 10:"dec", 16:"hex"}[base]
            return getattr(Bits(data, base = 2, bits = start-stop), key)

    def __getattr__(self, attr):
        base = self.Type[attr].value
        if base == 2:
            return self._bin()
        elif base == 10:
            return self._dec()
        elif base == 16:
            return self._hex()
        else:
            raise self.UnkonwnBase

        return None

    def __len__(self):
        return len(self.__data)

    def toint(self):
        return int(self.__data, 2)

    def _bin(self):
        return self.__data

    def _dec(self):
        data = self.toint()
        return "%d" % data

    def _hex(self):
        data = self.toint()
        l = len(self._bin()) // 8
        return ("0x%0" + str(l) + "x") % data

    def show(self, base = 16):
        if base not in self.base_list:
            raise self.UnkonwnBase

        if base == 2:
            print(self.bin)
        elif base == 10:
            print(self.dec)
        elif base == 16:
            print(self.hex)

if __name__ == "__main__":
    b = Bits("0x73fa")
    b.show(2)
    b.show(10)
    b.show(16)
    print(b[1:2:])
    print(b[:2:10])
    print(b[1::16])
