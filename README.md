# rtlentropy-arm-asuswrt

### HOWTO: Compile rtl-entropy for AsusWRT firmware
```
cd
git clone https://github.com/blackfuel/rtlentropy-arm-asuswrt.git
cd rtlentropy-arm-asuswrt
./rtlentropy.sh
```

### HOWTO: Automatically start hardware RNG entropy collection when the router is rebooted

__/jffs/scripts/init-start__
```
#!/bin/sh

/jffs/scripts/rtl-start.sh &
```

__/jffs/scripts/rtl-start.sh__
```
#!/bin/sh
/usr/bin/logger -t $(/usr/bin/basename $0) "custom script started [$$]"
finish()  {
  /usr/bin/logger -t $(/usr/bin/basename $0) "custom script ended [$$]"
}
trap finish EXIT

/bin/sleep 1

# wait for device to become ready, then start rtl_entropy and rngd

loop_wait=0
while : ; do
  if [ $loop_wait -eq 0 ]; then
    loop_wait=5
  else
    /usr/bin/logger -t $(/usr/bin/basename $0) "custom script waiting for hardware RNG to become ready [$$]"
    /bin/sleep $loop_wait
  fi

  # Realtek Semiconductor Corp. RTL2838 DVB-T
  /usr/bin/lsusb | /bin/grep -qi "0bda:2838"
  if [ $? -eq 0 ]; then

    if [ -n "$(/bin/pidof rtl_entropy)" ] || [ -n "$(/bin/pidof rngd)" ]; then
      /usr/bin/killall -9 rtl_entropy rngd >/dev/null 2>&1
      /bin/sleep 2
    fi

    [ -z "$(/bin/pidof rtl_entropy)" ] && /bin/rtl_entropy -b && /bin/sleep 5
    [ -z "$(/bin/pidof rtl_entropy)" ] && continue
    [ -z "$(/bin/pidof rngd)" ] && /sbin/rngd -r /var/run/rtl_entropy.fifo -W2000

    /usr/bin/logger -t $(/usr/bin/basename $0) "custom script started hardware RNG entropy collection [$$]"
    break
  fi
done
```

### Example: How to test it
`# cat /dev/random | rngtest -c 2048`  
```
rngtest 5
Copyright (c) 2004 by Henrique de Moraes Holschuh
This is free software; see the source for copying conditions.  There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

rngtest: starting FIPS tests...
rngtest: bits received from input: 40960032
rngtest: FIPS 140-2 successes: 2047
rngtest: FIPS 140-2 failures: 1
rngtest: FIPS 140-2(2001-10-10) Monobit: 0
rngtest: FIPS 140-2(2001-10-10) Poker: 0
rngtest: FIPS 140-2(2001-10-10) Runs: 0
rngtest: FIPS 140-2(2001-10-10) Long run: 1
rngtest: FIPS 140-2(2001-10-10) Continuous run: 0
rngtest: input channel speed: (min=27.580; avg=803.385; max=3906250.000)Kibits/s
rngtest: FIPS tests speed: (min=5.495; avg=62.288; max=70.905)Mibits/s
rngtest: Program run time: 50425310 microseconds
```
