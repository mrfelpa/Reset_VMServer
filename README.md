# Requirements

- To run this script, you must have VMware PowerCLI installed and configured in your environment.
- The variables in the script must be configured with information specific to your environment, such as the server’s IP address, the vCenter address, the vCenter user name and password, and the server’s virtual machine name, For example:

        $serverIP = 192.168.1.100
        $vcenterServer = vcenter.example.com
        $vcenterUser = administrator
        $vcenterPassword = password123
        $retryCount = 3 # Number of retry attempts
        $retryDelay = 5 # Delay between retry attempts (in seconds).

# Remarks

- Make sure that the variables in the script are configured with the correct information from your environment before running it.
- The script assumes that the server virtual machine has the same name as the server name. If the virtual machine name is different, set the $vmName variable accordingly.
- The script restarts the virtual machine without a confirmation prompt. Make sure that you are aware of the implications of this before running it.

# Future Improvements

- [ ] Send email notifications when a server is reset.
- [ ] Log events in a log.
