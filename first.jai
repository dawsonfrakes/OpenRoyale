DEBUG :: true;

#run {
	#import "Basic";
	#import "Compiler";

	set_build_options_dc(.{do_output = false});

	options := get_build_options();
	options.output_type = .EXECUTABLE;
	options.output_executable_name = "Open Royale";

	if !DEBUG options.additional_linker_arguments = .["-subsystem:windows", "-entry:mainCRTStartup"];

	w := compiler_create_workspace("Open Royale");
	set_build_options(options, w);
	add_build_string(tprint("DEBUG :: %;", DEBUG), w);
	if options.os_target == {
		case .WINDOWS;
			add_build_file("platform/main_windows.jai", w);
		case;
			print("Target % is not supported\n", options.os_target);
	}
}
