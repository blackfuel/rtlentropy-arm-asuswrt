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

# wait for device to become ready, then start rtl_entropy and rngd

while [ true ]; do
  # Realtek Semiconductor Corp. RTL2838 DVB-T
  /usr/bin/lsusb | /bin/grep -qi "0bda:2838"
  if [ $? -eq 0 ]; then

    if [ -n "$(/bin/pidof rtl_entropy)" ] || [ -n "$(/bin/pidof rngd)" ]; then
      /usr/bin/killall -9 rtl_entropy rngd >/dev/null 2>&1
      sleep 2
    fi

    [ -z "$(/bin/pidof rtl_entropy)" ] && /bin/rtl_entropy -b
    [ -z "$(/bin/pidof rngd)" ] && /sbin/rngd -r /var/run/rtl_entropy.fifo -W2000

    /usr/bin/logger -t $(/usr/bin/basename $0) "custom script started hardware RNG entropy collection [$$]"
    break

  else
    /usr/bin/logger -t $(/usr/bin/basename $0) "custom script waiting for hardware RNG to become ready [$$]"
    /bin/sleep 1
  fi
done
```
