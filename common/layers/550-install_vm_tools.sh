#!/bin/bash

$AS sh -c 'echo "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAqmQw7RdwQe6BKJE8dlp4u3wpPBFNRtGVoolcTjcc7I7aljh6lvK2EKc6nf73Fe418mjWbQFsADk3c0YTk1tkTqATu0wlP9BFEu6eogoT2qwEf8XE2+hsZiYzbJvYXArmvYVeowgkpuLNw3OuHJ1WL9mftmtnFmp3W2grih19H8fFBybYKJBFyS13Zbsui7hkjPbkroHh0OpofwhN4jggw5YffuJofKdGNTv08V7NdW+8wov9/3QCd65Tslwi0tYKPflzDTZW3HX3JVpCJ8VDr6zxlOgOCSW6ds9ATfpXaItTW9kRgyCQ+8jwlXnPBfMQioVK9+tVxqmXLY+6/ciH1w== rsa-key-20180116" >> /home/sergey/.ssh/authorized_keys'

/usr/bin/usermod -a -G vagrant ${LUSER}
