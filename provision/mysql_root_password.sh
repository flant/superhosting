#!/usr/bin/env /bin/bash

echo "USE mysql;\nALTER USER 'root'@'localhost' IDENTIFIED BY 'root';\nFLUSH PRIVILEGES;\n" | mysql -u root