#!/bin/sh

#
# This source file is part of the Apodini HotROD example open source project
#
# SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
#
# SPDX-License-Identifier: MIT
#

URL=http://localhost:8080/config
ITERATIONS=1000

rm $1

for i in $(seq $ITERATIONS)
do
  curl $URL -w "%{time_connect},%{time_total},%{speed_download},%{http_code},%{size_download},%{url_effective}\n" -o /dev/null -s >> $1
done
