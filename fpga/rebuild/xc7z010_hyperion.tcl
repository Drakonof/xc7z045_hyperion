# The setups field. ########################################

set vivado_vertion   "2018.3"          
set project_name      xc7z010_hyperion
set project_device    xc7z010clg400-1
set project_direction "."

set current_version [lindex [split $::env(XILINX_VIVADO) /] end]
if {![string equal $current_version $vivado_vertion]} {
    puts "THE VIVADO VERSION ERROR!"
    puts "There is requered a $requared_version vivado version,"
    puts "but is a $current_version version of the one."
    puts "THE PROCCESS WAS STOPPED."
    return
}


create_project -name $project_name -force -dir $project_direction -part $project_device

set_property top ${project_name} [get_filesets sources_1]

add_files -fileset [get_filesets sources_1] {*}[glob $project_direction/hdl/rtl/*.sv] 

add_files -fileset [get_filesets sim_1] {*}[glob $project_direction/hdl/tb/*.sv]

#add_files -fileset constrs_1 -norecurse $project_direction/xdc/${project_name}.xdc
#set_property used_in_synthesis true [get_files $project_direction/xdc/${project_name}.xdc]

#source $project_direction/bd/${project_name}_bd.tcl
#make_wrapper -files [get_files $project_direction/bd/${project_name}_bd/${project_name}_bd.bd] -top
#add_files -norecurse $project_direction/bd/${project_name}_bd/hdl/${project_name}_bd_wrapper.v

set_property "top" $project_name.sv [get_filesets sources_1]

update_compile_order -fileset sources_1

#launch_runs impl_1 -to_step write_bitstream -jobs 4