# Copyright 2016 Acquia, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative 'lookup_from_const'

module SumologicCloudSyslog
  module Severity
    extend LookupFromConst
    EMERG  = PANIC   = 0
    ALERT            = 1
    CRIT             = 2
    ERR    = ERROR   = 3
    WARN   = WARNING = 4
    NOTICE           = 5
    INFO             = 6
    DEBUG            = 7
    NONE             = 10
  end
end
