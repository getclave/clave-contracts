#!/bin/bash

# Clear the gas snapshot file
: > ./.gas-snapshot

# Print banner
echo "_______________________    ________________________________________________" >> ./.gas-snapshot;
echo "__  ____/__    |_  ___/    ___  __ \__  ____/__  __ \_  __ \__  __ \__  __/" >> ./.gas-snapshot;
echo "_  / __ __  /| |____ \     __  /_/ /_  __/  __  /_/ /  / / /_  /_/ /_  /   " >> ./.gas-snapshot;
echo "/ /_/ / _  ___ |___/ /     _  _, _/_  /___  _  ____// /_/ /_  _, _/_  /    " >> ./.gas-snapshot;
echo "\____/  /_/  |_/____/      /_/ |_| /_____/  /_/     \____/ /_/ |_| /_/     " >> ./.gas-snapshot;
echo "                                                                           " >> ./.gas-snapshot;

# Run the zksync era test node and read its output line by line
era_test_node --show-gas-details all run | while IFS= read -r line
do
    # If the line contains "gas" but not "cost", then process it
    if [[ "$line" == *"gas"* ]] && [[ "$line" != *"cost"* ]]; then
        # Get the last line of the gas snapshot file
        last_line=$(tail -n 1 ./.gas-snapshot)  
        
        # Check if the last line ends with any of the allowed substrings
        if [[ "$last_line" == *':"' || "$last_line" == *"gas" || "$last_line" == *"spent:" || "$last_line" == *"setup" || "$last_line" == *"etc)" || "$last_line" == *"validation" ]]; then
            # If it does, append the current line to the gas snapshot file
            echo "${line:29}" >> ./.gas-snapshot
        fi
    fi
done &
# Run the hardhat test in snapshot mode on the zkSyncTestnet network
hardhat test --network inMemoryNode
# Kill all instances of the zksync era test node
killall era_test_node
