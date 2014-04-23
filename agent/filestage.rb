require 'net/http'
require 'uri'
require 'json'

module MCollective
  module Agent
    class Filestage<RPC::Agent

      action "stage" do
        dest = Pathname.new(request[:dest])

        reply.fail!(reply[:summary] = "Cannot Stage File - destination directory not present: #{dest.dirname}") unless dest.dirname.exist? && dest.dirname.directory?
        reply.fail!(reply[:summary] = "Cannot Stage File - destination directory not writable: #{dest.dirname}") unless dest.dirname.writable?

        if dest.exist?
          unless request[:force]
            reply.fail!(reply[:summary] = "Cannot Stage File - destination file already exists. Set force to true to overwrite file")
          else
            Log.notice("Existing file will be attempted to be overwritten")
          end

          reply.fail!(reply[:summary] = "Cannot Stage File - cannot overwrite file at destination") unless dest.writable?
          reply.fail!("Cannot Stage File - exisitng file is a directory, cannot overwrite") if dest.directory?
        end

        uri = URI.parse(URI.escape(request[:source]))

        result = fork_stage(uri, dest)
      end

      action "status" do
      end

      def fork_stage(source, dest)
        begin
          lock = File.open("/tmp/staging_#{Time.now.to_i}", File::CREAT|File::TRUNC|File::RDWR, 0644)
          details = {:src => source.to_s, :dst => dest, :status => 'starting', :summary=> nil}
          lock.write(details.to_json)

          dstfile = File.open(dest, File::CREAT|File::TRUNC|File::RDWR)

        rescue Exception => e
          if lock.kind_of? File
            details[:status] = 'failed'
            details[:summary] = e.message
            lock.truncate 0
            lock.write(details.to_json)
            lock.close
          end

          reply.fail("Cannot Stage File - #{e.message}")
        end

        child = fork do
          grandchild = fork do
            case source.scheme
              when 'http', 'https'
                details[:status] = "running"
                details[:summary] = "Staging from #{source.to_s} to #{dest}"
                lock.truncate 0
                lock.write(details.to_json)
                begin
                  Net::HTTP.start(source.host, source.port, :use_ssl => source.scheme == 'https'){ |http|
                    http.request_get(source.path){ |resp|
                      resp.read_body { |seg|
                        dstfile.write(seg)
                      }
                    }
                  }

                rescue Exception => e
                  details[:status] = "failed"
                  details[:summary] = "Cannot Stage File - #{e.message}"
                ensure
                  dstfile.close
                  lock.truncate 0
                  lock.write(details.to_json)
                end
              when 'ftp'
                # Fill Me In!
                dstfile.close

              when 'file', nil
                details[:status] = 'running'
                details[:summary] = "Copying file from #{source.path} to #{dest}"
                lock.truncate 0
                lock.write(details.to_json)

                begin
                  dstfile.close
                  FileUtils.cp(source.path, dest)

                rescue Exception => e
                  details[:status] = 'failed'
                  details[:summary] = "Cannot stage file from #{source.path} - #{e.message}"
                else
                  details[:status] = 'success'
                  details[:summary] = "Finished Staging #{dest}"
                ensure
                  lock.truncate 0
                  lock.write(details.to_json)
                end
              end
            lock.close
          end

          lock.close
          dstfile.close
          if grandchild
            Process.detach(grandchild)
          end
        end

        lock.close
        dstfile.close

        return 1 if child.nil?
        if child
          Process.detach(child)
          return 0
        end
      end
    end
  end
end
