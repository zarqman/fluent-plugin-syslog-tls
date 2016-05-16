require 'socket'
require 'openssl'

class SSLTest < Test::Unit::TestCase
    def ssl_server
        @ssl_server ||= begin
            tcp_server = TCPServer.new("localhost", 33000 + Random.rand(1000))
            ssl_context = OpenSSL::SSL::SSLContext.new
            ssl_context.cert = certificate
            ssl_context.key = rsa_key
            OpenSSL::SSL::SSLServer.new(tcp_server, ssl_context)
        end
    end

    def ssl_client
      tcp = TCPSocket.new("localhost", ssl_server.addr[1])
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.set_params(verify_mode: OpenSSL::SSL::VERIFY_NONE)
      ctx.cert = certificate
      ctx.key = rsa_key
      OpenSSL::SSL::SSLSocket.new(tcp, ctx)
    end

    def rsa_key
        @rsa_key ||= OpenSSL::PKey::RSA.new(2048)
    end

    def certificate
        @cert ||= begin
            subject = "/C=BE/O=Test/OU=Test/CN=Test"

            @cert = OpenSSL::X509::Certificate.new
            @cert.subject = @cert.issuer = OpenSSL::X509::Name.parse(subject)
            @cert.not_before = Time.now
            @cert.not_after = Time.now + 365 * 24 * 60 * 60
            @cert.public_key = rsa_key.public_key
            @cert.serial = 0x0
            @cert.version = 2

            ef = OpenSSL::X509::ExtensionFactory.new
            ef.subject_certificate = @cert
            ef.issuer_certificate = @cert
            @cert.extensions = [
                ef.create_extension("basicConstraints","CA:TRUE", true),
                ef.create_extension("subjectKeyIdentifier", "hash"),
                # ef.create_extension("keyUsage", "cRLSign,keyCertSign", true),
            ]
            @cert.add_extension ef.create_extension("authorityKeyIdentifier", "keyid:always,issuer:always")
            @cert.sign(rsa_key, OpenSSL::Digest::SHA1.new)
            @cert
        end
    end
end