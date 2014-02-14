metadata :name        => 'File Staging Agent',
         :description => 'Agent to manage the staging of files to a node over a network connection',
         :author      => 'Thomas Linkin',
         :license     => 'Apache 2.0',
         :version     => '0.1',
         :url         => '',
         :timeout     => 120

action "stage", :description => 'Stage a file from a source to a destination' do

  input :source,
        :promt       => 'File Source',
        :description => 'Remote location to stage file from',
        :optional     => false,
        :type        => :string,
        :validation  => :stage_src,
        :maxlength   => 0

  input :dest,
        :promt       => 'File Destination',
        :description => 'Destination on the end system to store file',
        :optional     => false,
        :type        => :string,
        :validation  => :absolute_file_path,
        :maxlength   => 0

  input :force,
        :promtp      => 'Force Overwrite',
        :description => 'Force the overwrite of file already at the destination',
        :type        => :bool,
        :default     => false,
        :optional     => false

  output :summary,
         :description => "Initial status of the staging operation",
         :display_as  => "Operation Status",
         :default     => "unknown status"
end

action "status", :description => 'Display status of running stage operations' do

  input :dest,
        :promt       => 'Operation Destination',
        :description => 'Destination of operation to obtain status of',
        :optional     => true,
        :type        => :string,
        :validation  => :absolute_path,
        :maxlength   => 0

  output :status,
         :description => "Status of currently running operation(s)",
         :display_as  => "Currently Running Operation Status(es)"
end
