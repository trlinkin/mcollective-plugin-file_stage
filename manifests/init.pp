class mcollective_plugin_file_stage{
  include ::mcollective_plugin

  mcollective_plugin::plugin { 'filestage':
    type => 'agent',
  }

  mcollective_plugin::plugin { 'absolute_file_path':
    type => 'validator',
  }

  mcollective_plugin::plugin { 'staging_src':
    type => 'validator',
  }
}
