#!/bin/bash
cd ..
docker run -ti --rm --net=host -v $(pwd):/funkadelic:rw  funkadelic bash -c "cd ../funkadelic ; node out.js"
