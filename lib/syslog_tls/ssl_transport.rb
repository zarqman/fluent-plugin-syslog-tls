# Copyright 2016 Acquia, Inc.
# Copyright 2016 t.e.morgan.
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
    CONNECT_TIMEOUT = 10
    # READ_TIMEOUT    = 5
    WRITE_TIMEOUT   = 5

    attr_accessor :socket

    attr_reader :host, :port, :idle_timeout, :client_cert, :client_key, :ssl_version

    attr_writer :retries

    def initialize(host, port, idle_timeout: nil, client_cert: nil, client_key: nil, ssl_version: :TLSv1_2, max_retries: 1)
      @host = host
      @port = port
      @idle_timeout = idle_timeout
      @client_cert = client_cert
      @client_key = client_key
      @ssl_version = ssl_version
      @retries = max_retries
      connect
    end

    def connect
      @socket = get_ssl_connection
      begin
        begin
          @socket.connect_nonblock
        rescue Errno::EAGAIN, Errno::EWOULDBLOCK, IO::WaitReadable
          select_with_timeout(@socket, :connect_read) && retry
        rescue IO::WaitWritable
          select_with_timeout(@socket, :connect_write) && retry
        end
      rescue Errno::ETIMEDOUT
        raise 'Socket timeout during connect'
      end
      @last_write = Time.now if idle_timeout
    end

    def get_tcp_connection
      tcp = nil

      family = Socket::Constants::AF_UNSPEC
      sock_type = Socket::Constants::SOCK_STREAM
      addr_info = Socket.getaddrinfo(host, port, family, sock_type, nil, nil, false).first
      _, port, _, address, family, sock_type = addr_info

      begin
        sock_addr = Socket.sockaddr_in(port, address)
        tcp = Socket.new(family, sock_type, 0)
        tcp.setsockopt(Socket::SOL_SOCKET, Socket::Constants::SO_REUSEADDR, true)
        tcp.setsockopt(Socket::SOL_SOCKET, Socket::Constants::SO_REUSEPORT, true)
        tcp.connect_nonblock(sock_addr)
      rescue Errno::EINPROGRESS
        select_with_timeout(tcp, :connect_write)
        begin
          tcp.connect_nonblock(sock_addr)
        rescue Errno::EISCONN
          # all good
        rescue SystemCallError
          tcp.close rescue nil
          raise
        end
      rescue SystemCallError
        tcp.close rescue nil
        raise
      end

      tcp.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
      tcp
    end

    def get_ssl_connection
      tcp = get_tcp_connection

      ctx = OpenSSL::SSL::SSLContext.new
      ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
      ctx.ssl_version = ssl_version

      ctx.cert = OpenSSL::X509::Certificate.new(File.read(client_cert)) if client_cert
      ctx.key = OpenSSL::PKey::read(File.read(client_key)) if client_key
      socket = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
      socket.sync_close = true
      socket
    end

    # Allow to retry on failed writes
    def write(s)
      if idle_timeout
        if (t=Time.now) > @last_write + idle_timeout
          @socket.close rescue nil
          connect
        else
          @last_write = t
        end
      end
      begin
        retry_id ||= 0
        do_write(s)
      rescue => e
        if (retry_id += 1) < @retries
          @socket.close rescue nil
          connect
          retry
        else
          raise e
        end
      end
    end

    def do_write(data)
      data.force_encoding('BINARY') # so we can break in the middle of multi-byte characters
      loop do
        sent = 0
        begin
          sent = @socket.write_nonblock(data)
        rescue OpenSSL::SSL::SSLError, Errno::EAGAIN, Errno::EWOULDBLOCK, IO::WaitWritable => e
          if e.is_a?(OpenSSL::SSL::SSLError) && e.message !~ /write would block/
            raise e
          else
            select_with_timeout(@socket, :write) && retry
          end
        end

        break if sent >= data.size
        data = data[sent, data.size]
      end
    end

    def select_with_timeout(tcp, type)
      o = case type
      when :connect_read
        args = [[tcp], nil, nil, CONNECT_TIMEOUT]
      when :connect_write
        args = [nil, [tcp], nil, CONNECT_TIMEOUT]
      # when :read
      #   args = [[tcp], nil, nil, READ_TIMEOUT]
      when :write
        args = [nil, [tcp], nil, WRITE_TIMEOUT]
      else
        raise "Unknown select type #{type}"
      end
      IO.select(*args) || raise("Socket timeout during #{type}")
    end

    # Forward any methods directly to SSLSocket
    def method_missing(method_sym, *arguments, &block)
      @socket.send(method_sym, *arguments, &block)
    end
  end
end
