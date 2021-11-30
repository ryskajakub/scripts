#!/usr/bin/env -S node --experimental-modules

import { execSync } from 'child_process'

const branch_name = execSync('git rev-parse --abbrev-ref HEAD').toString().trim()
execSync(`git commit -m ${branch_name}`)
