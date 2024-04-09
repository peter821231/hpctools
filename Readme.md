# ibcheck.sh README

## Description
ibcheck.sh is a script that performs various checks on InfiniBand (IB) network configurations.

## Prerequisites
- InfiniBand hardware and drivers installed
- Bash shell

## Usage

1. Make the script executable:
    ```bash
    chmod +x ibcheck.sh
    ```
2. Edit default OFFLINE port mapping
    ```bash
    # Variable format: IB{LF/SP}{Switch number}=(port1 port2 port3 ...)
    IBSP01=(47 48 51 52 61 62 63 64)
    ```
3. Run the script:
    ```bash
    ./ibcheck.sh
    ```
4. Get the result:
    ```bash
    Check switch and port status by iblinkinfo
    Format: physical port(virtual port)
    All Switches online OK
    IBLF01 OK
    IBLF02 OK
    IBLF03 OK
    IBLF04 OK
    IBLF05 OK
    IBLF06 OK
    IBLF07 OK
    IBLF08 OK
    IBLF09 OK
    IBLF10 OK
    IBLF11 port 3(10) Down
    IBLF11 port 3(11) Down
    IBLF11 port 26(102) Down
    IBLF11 port 26(103) Down
    IBLF12 OK
    IBLF13 OK
    IBLF14 OK
    IBLF15 OK
    IBSP01 OK
    IBSP02 OK
    IBSP03 OK
    IBSP04 OK
    IBSP05 OK
    IBSP06 OK
    IBSP07 OK
    IBSP08 OK
    ```

## Features
- Check IB link and port status

## Contributing
Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.