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

module SyslogTls
  # Supports SSL connection to remote host
  class SSLTransport
    attr_accessor :socket

    attr_reader :host, :port, :ca_cert, :cert, :key, :ssl_version

    attr_writer :retries

    def initialize(host, port, ca_cert: 'system', cert: nil, key: nil, ssl_version: :TLSv1_2, max_retries: 1)
      @ca_cert = ca_cert
      @host = host
      @port = port
      @cert = cert
      @key = key
      @ssl_version = ssl_version
      @retries = max_retries
      connect
    end

    def connect
      @socket = get_ssl_connection
      @socket.connect
    end

    def get_ssl_connection
      tcp = TCPSocket.new(host, port)

      ctx = OpenSSL::SSL::SSLContext.new
      ctx.set_params(verify_mode: OpenSSL::SSL::VERIFY_PEER)
      ctx.ssl_version = ssl_version

      case ca_cert
      when true, 'true', 'system'
        # use system certs, same as openssl cli
        ctx.cert_store = OpenSSL::X509::Store.new
        ctx.cert_store.set_default_paths
      when false, 'false'
        ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
      when %r{/$} # ends in /
        ctx.ca_path = ca_cert
      when String
        ctx.ca_file = ca_cert
      end

      ctx.cert = OpenSSL::X509::Certificate.new(File.read(cert)) if cert
      ctx.key = OpenSSL::PKey::read(File.read(key)) if key
      socket = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
      socket.sync_close = true
      socket
    end

    # Allow to retry on failed writes
    def write(s)
      begin
        retry_id ||= 0
        @socket.send(:write, s)
      rescue => e
        if (retry_id += 1) < @retries
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
