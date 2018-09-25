// kv-store.sol

pragma solidity ^0.4.0;

contract KVStore {
    int256 public count;
    mapping (bytes => bytes) data;

    event Log(string which, bytes key, bytes value);

    function put(bytes key, bytes value, bool log) public returns (int inc) {
        if (data[key].length == 0) {
            inc = 1;
            count++;
        }
        data[key] = value;
        if (log) {
            emit Log("put", key, value);
        }
    }

    // _data is tightly packed.
    // if not use: ix += 0x20 + (k.length+31)/32*32, instead of
    //             ix += 0x20 + k.length
    function mput(bytes _data, bool log) public returns (int cnt) {
        bytes memory k;
        bytes memory v;
        uint ix;
        uint eix;

        assembly {
            ix := add(_data, 0x20)
        }
        eix = ix + _data.length;

        while (ix < eix) {
            assembly {
                k := ix
            }
            ix += 0x20 + k.length;
            require(ix < eix);
            assembly {
                v := ix
            }
            ix += 0x20 + v.length;
            require(ix <= eix);

            if (data[k].length == 0) {
                cnt++;
            }
            data[k] = v;
        }
        count += cnt;
        if (log) {
            emit Log("mput", "", "");
        }
    }

    function del(bytes key) public {
        if (data[key].length != 0) {
            count--;
            delete data[key];
        }
    }

    function get(bytes key) public view returns (bytes value) {
        value = data[key];
    }
}

// EOF
