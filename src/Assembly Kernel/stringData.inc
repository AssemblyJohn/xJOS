   ; =================
   ; A lot of string data
   ; =================
   
   ; strings
   msg_welcome db 'Welcome to John''s OS!', 0x0D, 0x0A
   msg_w01     db 'Type ''help'' for help', 0x0D, 0x0A, 0
   msg_welcome_back db 'Welcome back to the kernel!', 0x0D, 0x0A, 0

   msg_helloworld db 'Hello UVT!', 0x0D, 0x0A, 0

   ; propt to know where to write
   cmd_prompt db '>>', 0

   ; personal commands
   cmd_hi	db 'hi', 0
   cmd_help	db 'help', 0
   cmd_xhelp	db 'xhelp', 0
   cmd_diagnose db 'diagnose', 0
   cmd_ticks	db 'ticks', 0
   cmd_dump	db 'dump', 0
   cmd_cls	db 'cls', 0
   cmd_a20	db 'a20', 0
   cmd_time	db 'time', 0
   cmd_restart	db 'restart',0
   cmd_ls		db 'ls', 0
   cmd_exec		db 'exec', 0
   cmd_xprot	db 'xprot', 0
   cmd_space	db ' ', 0

   ; help/other important messages
   msg_badcommand db 'Bad command entered.                        ', 0x0D, 0x0A, 0
   msg_not_avail  db 'Feature under construction.', 0x0D, 0x0A, 0

   msg_for_help db 0x0D, 0x0A, ' Available commands:', 0x0D, 0x0A
   msg_h00	db '   hi, xhelp, diagnose, ticks, dump,', 0x0D, 0x0A
   msg_h02	db '   protected, a20, time, ls, restart, exec, xprot', 0x0D, 0x0A, 0x0D, 0x0A
   msg_h01	db ' For extended help type in xhelp', 0x0D, 0x0A, 0x0D, 0x0A, 0

   msg_help_ext db 0x0D, 0x0A,' Extended help:', 0x0D, 0x0A, 0x0D, 0x0A
   msg_he01	db '   hi - prints a greeting', 0x0D, 0x0A
   msg_he02	db '   diagnose - prints info about PC (memory, cpu)', 0x0D, 0x0A
   msg_he03	db '   ticks - ticks since midnight in hexa', 0x0D, 0x0A
   msg_he05	db '   cls - clears screen', 0x0D, 0x0A
   msg_he06	db '   a20 - a20 line checks', 0x0D, 0x0A
   msg_he08	db '   time - display time', 0x0D, 0x0A
   msg_he09	db '   restart - restarts computer', 0x0D, 0x0A
   msg_he04	db '   dump - dumps all general registers', 0x0D, 0x0A
   msg_he10	db '   ls - lists all root files', 0x0D, 0x0A
   msg_he11	db '   exec - executes a binary program', 0x0D, 0x0A
   msg_he07	db '   xprot - loads the ''xprot'' kernel, goes', 0x0D, 0x0A
   msg_he13	db '   to protected, mode loads the kernel at 0x00100000', 0x0D, 0x0A
   msg_he12 db '   and begins to execute it(do not use it firstly!)' ,0x0D, 0x0A, 0x0D, 0x0A, 0
   
   ; other data for printing
   msg_a20_yes	db 'A20 line is enabled!', 0x0D, 0x0A, 0
   msg_a20_not	db 'A20 line is not enabled, enabling now...', 0x0D, 0x0A
   msg_a20_00  db  'Recomended to use ''a20'' again.', 0x0D, 0x0A, 0
   msg_time	    db 'Time: ', 0
   msg_time_sep db ':',0
   msg_restart db 'Press any key to restart...',0
   msg_disk_error db 'Error in reading the disk... Try again.',0

   msg_memory_error db 'Error in reading memory!', 0x0D, 0x0A, 0
   msg_memory_low_ok	db 'Low memory available: ', 0
   
   ; =================
   ; file module strings
   ; =================
   file_utils_error db 'Fatal error while working with diskette!', 0
   file_succes db 'Succes loading file at the specified location!',0x0D, 0x0A
   file_succ01 db 'Ready to jump there!', 0x0D, 0x0A, 0
   file_not_found db 'File not found!', 0
   file_input_filename db 'Input filename: ', 0x0D, 0x0A, 0
   file_got_name db 'Filename got: ', 0
   file_read_root_dirs_succes db 'Reading root entries was a success!', 0x0D, 0x0A ,0
   file_test db 'Test at...', 0x0D, 0x0A, 0
   
   file_xprot_info	  db 'Loading everything to enter protected mode and for', 0x0D, 0x0A
   fine_xprot_i_msg01 db 'loading the kernel above the 1MB low mem and executing it', 0x0D, 0x0A, 0
   file_xprot_success db 'XPROT.BIN loaded with success!', 0x0D, 0x0A, 0
   file_xprot_failure db 'XPROT.BIN not loaded!', 0x0D, 0x0A, 0
   file_xprot db 'XPROT   BIN'

   ; registers for printing
   reg_cs      db 'CS: ', 0
   reg_ip      db 'IP: ', 0
   reg_ax      db 'AX: ', 0
   reg_bx      db 'BX: ', 0
   reg_cx      db 'CX: ', 0
   reg_dx      db 'DX: ', 0
   reg_si      db 'SI: ', 0
   reg_di      db 'DI: ', 0
   reg_ds      db 'DS: ', 0
   reg_es      db 'ES: ', 0
   reg_ss      db 'SS: ', 0
   reg_sp      db 'SP: ', 0
   reg_bp      db 'BP: ', 0