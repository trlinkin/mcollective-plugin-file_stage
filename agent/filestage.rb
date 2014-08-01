require 'net/http'
require 'uri'
require 'json'

module MCollective
  module Agent
    class Filestage<RPC::Agent

      action "stage" do
        dest = Pathname.new(request[:dest])

        reply.fail!("Cannot Stage File - destination directory not present: #{dest.dirname}") unless dest.dirname.exist? && dest.dirname.directory?
        reply.fail!("Cannot Stage File - destination directory not writable: #{dest.dirname}") unless dest.dirname.writable?

        if dest.exist?
          unless request[:force]
            reply.fail!("Cannot Stage File - destination file already exists. Set force to true to overwrite file")
          else
            Log.info("Existing file will be attempted to be overwritten")
          end
          reply.fail!("Cannot Stage File - cannot overwrite file at destination") unless dest.writable?
          reply.fail!("Cannot Stage File - exisitng file is a directory, cannot overwrite") if dest.directory?
        end

        uri = URI.parse(URI.escape(request[:source]))

        fork_stage(uri, dest)

        reply.statusmsg = "Starting Stage Operation from #{uri} to #{dest}"
      end

      action "status" do
        results = String.new

        Dir.glob('/tmp/staging_*').sort.each do |file|
          begin
            status_json = File.read(file)
            status = JSON.parse(status_json)
            if request[:dest] && request[:dest] == status['dst']
              results = format_status(status)
              reply[:status] = status['status']
              break
            elsif request[:dest].nil?
              results << format_status(status)
              reply['status'] = 'aggregate'
            end
          end
        end

        if results.empty?
          results = "No status(es) found"
        end

        reply.statusmsg = results
      end

      def fork_stage(source, dest)
        begin
          start_time = Time.now.to_i
          lock = File.open("/tmp/staging_#{start_time}", File::CREAT|File::TRUNC|File::RDWR, 0644)
          details = {:src => source.to_s, :dst => dest, :status => 'starting', :summary=> nil, :start_time => start_time}
          lock.write(details.to_json)

          dstfile = File.open(dest, File::CREAT|File::TRUNC|File::RDWR)

        rescue Exception => e
          if lock.kind_of? File
            details[:status] = 'failed'
            details[:summary] = e.message
            lock.truncate(0)
            lock.seek(0)
            lock.write(details.to_json)
            lock.close
          end

          reply.fail!("Cannot Stage File - #{e.message}")
        end

        child = fork do
          grandchild = fork do

            # Set the process name so we don't lock the restarting of MCO
            $0 = "filestage #{dest}"

            case source.scheme
              when 'http', 'https'
                details[:status] = "running"
                details[:summary] = "Staging from #{source.to_s} to #{dest}"
                lock.truncate(0)
                lock.seek(0)
                lock.write(details.to_json)
                lock.flush
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
                else
                  details[:status] = 'success'
                  details[:summary] = "Finished Staging #{dest}"
                ensure
                  dstfile.close
                  lock.truncate(0)
                  lock.seek(0)
                  lock.write(details.to_json)
                end
              when 'ftp'
                # Fill Me In!
                dstfile.close

              when 'file', nil
                details[:status] = 'running'
                details[:summary] = "Copying file from #{source.path} to #{dest}"
                lock.truncate(0)
                lock.seek(0)
                lock.write(details.to_json)
                lock.flush

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
                  lock.truncate(0)
                  lock.seek(0)
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

        reply.fail!("Stage Failed to Start, please check operation lock file") unless child
        if child
          Process.detach(child)
        end
      end

      def format_status(status)

        operation_time = "#{Time.at(status['start_time'].to_i).localtime} #{Time.now.getlocal.zone}"

        "\n---------------------------------------------\n"\
        "Destination: #{status['dst']}\n\n"\
        "Source:      #{status['src']}\n"\
        "Status:      #{status['status']}\n"\
        "Summary:     #{status['summary']}\n"\
        "Started:     #{operation_time}\n"\
        "---------------------------------------------\n"
      end
    end
  end
end
