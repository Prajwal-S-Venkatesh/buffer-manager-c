# Buffer Manager

Implemented on top of storage manager: https://github.com/Prajwal-S-Venkatesh/buffer-manager-c.git

## How to run the code

To compile, build and run the test cases, use the following commands

```bash
make clean && make && make run_test_1 && make run_test_2 && make clean
```

or in short...

```bash
make run
```

## Solution Approach

### Interfaces for Pool Handling

-  **initBufferPool():** 
    - Check if the pageFile is NULL, if yes return `RC_FILE_NOT_FOUND`
    - Try to open the file in read and write mode, if the file is not found, return `RC_FILE_NOT_FOUND`
    - Close the file to avoid memory leaks, if the file exists
    - Update the Buffer Pool attributes like pageFile, numPages and replacement strategy
    - Allocate memory for mgmtData and assign it to the buffer pool
      - initialize the numReadIO
      - initialize the numWriteIO
      - initialize the queueHead (Used for FIFO)
      - Allocate memory for page frames
        - Initialize the page frame attributes such as page number, dirty bit, fix count, data
    - Update mgmtData pointer in the buffer pool with the above allocated memory
    - Return `RC_OK` if the buffer pool is initialized successfully

-  **shutdownBufferPool():**
    - Check if buffer pool is not existing, if yes return `RC_BUFFER_POOL_NOT_INIT`
    - Allocate memory for `mgmtData`
    - Flush dirty pages to disk before destroying the buffer pool
      - If the page is dirty, and has no fix count, write it back to disk
      - Write the dirty page back to disk
      - Increment the number of write IOs
    - Free the memory allocated for page frames
    - Free the memory allocated for mgmtData
    - Reset the mgmtData pointer in the buffer pool
    - Return `RC_OK` if the buffer pool is shutdown successfully

-  **forceFlushPool():**
    - Check if buffer pool is not existing, if yes return `RC_BUFFER_POOL_NOT_INIT`
    - Allocate memory for `mgmtData`
    - Perform a forced flush operation for all dirty pages with fix count 0 in the buffer pool
      - If the page is dirty, and has no fix count, write it back to disk
      - Write the dirty page back to disk
      - Increment the number of write IOs
      - Mark the page as not dirty after it has been written back to disk
    - Return `RC_OK` if the buffer pool is shutdown successfully

### Interfaces for Pages Access

-  **markDirty():**
    - Check if buffer pool is not existing
    - Get the mgmtData pointer from the buffer pool
    - Find the target page in the buffer pool
    - If the page is not found in the buffer pool, return an error `RC_READ_NON_EXISTING_PAGE`
    - Mark the page as dirty
    - Return `RC_OK` if the page is marked dirty successfully

-  **unpinPage():**
    - Check if buffer pool is not existing
    - Get the mgmtData pointer from the buffer pool
    - Find the target page in the buffer pool
    - If the page is not found in the buffer pool, return an error `RC_READ_NON_EXISTING_PAGE`
    - Decrement the fix count
    - Return `RC_OK` if the page is unpinned successfully

-  **forcePage():**
    - Check if buffer pool is not existing
    - Get the mgmtData pointer from the buffer pool
    - Find the target page in the buffer pool
    - If the page is not found in the buffer pool, return an error `RC_READ_NON_EXISTING_PAGE`
    - Write the page back to disk
    - Increment the number of write IOs
    - Set the page as not dirty
    - Return `RC_OK` if successfully forced page write

-  **pinPage():**
    - Check for invalid page number, if yes return `RC_READ_NON_EXISTING_PAGE`
    - Based on the replacement strategy defined in buffer pool, call the respective replacement strategy
      - FIFO (First-In-First-Out)
        - The function `findPage_FIFO` is defined to search for a target page within a buffer pool implemented using the FIFO replacement strategy.
        - The function iterates over the frames in the buffer pool and checks if the target page matches the page in a frame or if the frame is empty.
        - If a match is found, the index of the frame is returned, indicating the location of the target page.
        - The code also includes a function `findVictimPage_FIFO` that finds a victim page using the FIFO replacement strategy based on a fix count and a circular queue.
        - Start searching for the victim page from the next position after the queue head.
        - Iterates through the frames, checking if a frame has a fix count of zero, indicating it is a candidate for eviction.
        - If a frame with a fix count of zero is found, its index is returned as the victim page index.
        - The `pinPageUsingFIFO` function is responsible for pinning a page using the FIFO replacement strategy in the buffer pool.
        - It calls `findPage_FIFO` to check if the requested page is already present in the buffer pool. If not, it finds a victim page using `findVictimPage_FIFO`.
        - The function then retrieves the requested page from disk, updates the necessary metadata, and returns the pinned page with its corresponding information.
      - LRU (Least Recently Used)
        - The code includes a function `pinPageUsingLRU` to pin a page using the LRU replacement strategy in the buffer pool.
        - It checks if the buffer pool exists and retrieves the management data and frames from the buffer pool structure.
        - The function attempts to find the target page in the buffer pool using the findPage_LRU function.
        - If the page is found in the buffer pool, it updates the page handle with the existing page information, increments the fix count, and moves the page to the front of the LRU list.
        - The read count is incremented if the page was not already present in the buffer pool.
        - If the page is not found in the buffer pool, the function finds a victim frame using the `findLRUVictim function`.
        - If a victim frame is found, it checks if the victim page is dirty and writes it back to disk if necessary.
        - The victim frame is then updated with the new page information, including the page data retrieved from disk.
        - The page handle is updated with the new page information, and the accessed frame is moved to the front of the LRU list.
        - `updateLRUList` function is implemented to update the accessed frame's access count to the highest count, and the `findPage_LRU` function to find the target page using the LRU strategy and return its frame index.
      - LRU_K (Least Recently Used with K Counters) **(Implemented for bonus 5%)**
        - The function `pinPageUsingLRU_K` is used to pin a page using the LRU-K algorithm in the buffer pool.
        - It checks if the buffer pool exists and retrieves the management data and frames from the buffer pool structure.
        - The function attempts to find the target page in the buffer pool using the `findPage_LRU` function, which follows the LRU strategy.
        - If the page is found in the buffer pool, it updates the page handle with the existing page information, increments the fix count, and moves the page to the front of the LRU list using the `updateLRUList` function.
        - The read count is incremented to keep track of the number of page reads.
        - If the page is not found in the buffer pool, the function finds a victim frame using the LRU-K strategy by calling the `findLRUVictim` function.
        - If a victim frame is found, it checks if the victim page is dirty and writes it back to disk if necessary.
        - The victim frame is then updated with the new page information, including the page data retrieved from disk, fix count of 1, and clearing the dirty flag.
        - The page handle is updated with the new page information, and the accessed frame is moved to the front of the LRU list.
        - Return the appropriate result code based on the success of pinning the page or the availability of frames.


### Statistics Interface

-  **getFrameContents():**
    - Check if buffer pool is not existing, if yes return `RC_BUFFER_POOL_NOT_INIT`
    - Store the mgmt data
    - Create an PageNumber array to store pagenumbers
    - Create a PAGE_FRAME array and store the frames in it from mgmtdata
    - Create an integer to be used for position and initialise it with zero
    - Create an integer to store number of pages
    - Create a while loop that iterates as long as position is less than total number of pages
      - Store the pagenumber in the array at the appropriate position
    - Return the  array
    
-  **getDirtyFlags():**
    - Check if buffer pool is not existing, if yes return `RC_BUFFER_POOL_NOT_INIT`
    - Store the mgmt data
    - Create an bool array to store the values
    - Create a PAGE_FRAME array and store the frames in it from mgmtdata
    - Create an integer to be used for position and initialise it with zero
    - Create an integer to store number of pages
    - Create a while loop that iterates as long as position is less than total number of pages
      - Each iteration checks if the associated frame is dirty, if yes the array is assigned 'true' else 'false' at the appropriate position
    - Return the bool array
    
-  **getFixCounts():**
    - Check if buffer pool is not existing, if yes return `RC_BUFFER_POOL_NOT_INIT`
    - Store the mgmt data
    - Create an integer array to store the fix count 
    - Create a PAGE_FRAME array and store the frames in it from mgmtdata
    - Create an integer to be used for position and initialise it with zero
    - Create an integer to store number of pages
    - Create a while loop that iterates as long as position is less than total number of pages
      - Each iteration assigns fixcount value to the integer array by positional value
    - Return the integer array
    
-  **getNumReadIO():**
    - Check if buffer pool is not existing, if yes return `RC_BUFFER_POOL_NOT_INIT`
    - Store the mgmt data
    - Return the numReadIO
    
-  **getNumWriteIO():**
    - Check if buffer pool is not existing, if yes return `RC_BUFFER_POOL_NOT_INIT`
    - Store the mgmt data
    - Return the numWriteIO