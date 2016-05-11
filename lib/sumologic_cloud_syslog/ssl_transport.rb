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

require 'socket'
require 'openssl'

module SumologicCloudSyslog
  # Supports SSL connection to remote host
  class SSLTransport
    attr_accessor :socket

    attr_reader :host, :port, :cert, :key, :ssl_version

    attr_writer :retries

    def initialize(host, port, cert: nil, key: nil, ssl_version: :TLSv1_2, max_retries: 1)
      @host = host
      @port = port
      @cert = cert
      @key = key
      @ssl_version = ssl_version
      @retries = max_retries
      connect
    end

    def connect
      tcp = TCPSocket.new(host, port)

      ctx = OpenSSL::SSL::SSLContext.new
      ctx.set_params(verify_mode: OpenSSL::SSL::VERIFY_PEER)
      ctx.ssl_version = ssl_version

      ctx.cert = OpenSSL::X509::Certificate.new(File.open(cert)) if cert
      ctx.key = OpenSSL::PKey::RSA.new(File.open(key)) if key

      @socket = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
      @socket.connect
    end

    # Allow to retry on failed writes
    def write(s)
      begin
        retry_id ||= 0
        @socket.send(:write, s)
      rescue => e
        if (retry_id += 1) < retries
          connect
          retry
        else
          raise e
        end
      end
    end

    # Forward any methods directly to SSLSocket
    def method_missing(method_sym, *arguments, &block)
      @socket.send(method_sym, *arguments, &block)
    end
  end
end
