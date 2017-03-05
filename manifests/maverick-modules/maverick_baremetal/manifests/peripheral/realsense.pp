class maverick_baremetal::peripheral::realsense (
) {

    ensure_packages(["libglfw3", "libglfw3-dev", "libusb-1.0-0", "libusb-1.0-0-dev", "pkg-config", "libssl-dev", "liblz4-dev", "liblog4cxx-dev"])

    # Clone source from github
    oncevcsrepo { "git-realsense-librealsense":
        gitsource   => "https://github.com/IntelRealSense/librealsense.git",
        dest        => "/srv/maverick/var/build/librealsense",
    } ->
    
    # Create build directory
    file { "/srv/maverick/var/build/librealsense/build":
        ensure      => directory,
        owner       => "mav",
        group       => "mav",
        mode        => 755,
    } ->
    
    # Build and install
    exec { "librealsense-prepbuild":
        user        => "mav",
        timeout     => 0,
        command     => "/usr/bin/cmake -DBUILD_EXAMPLES=true -DCMAKE_INSTALL_PREFIX=/srv/maverick/software/librealsense -DCMAKE_INSTALL_RPATH=/srv/maverick/software/librealsense/lib ..",
        cwd         => "/srv/maverick/var/build/librealsense/build",
        creates     => "/srv/maverick/var/build/librealsense/build/Makefile",
        require     => [ File["/srv/maverick/var/build/librealsense/build"], Package["libglfw3-dev"], Package["libusb-1.0-0-dev"] ], # ensure we have all the dependencies satisfied
    } ->
    exec { "librealsense-build":
        user        => "mav",
        timeout     => 0,
        command     => "/usr/bin/make -j${::processorcount} >/srv/maverick/var/log/build/librealsense.build.out 2>&1",
        cwd         => "/srv/maverick/var/build/librealsense/build",
        creates     => "/srv/maverick/var/build/librealsense/build/librealsense.so",
        require     => Exec["librealsense-prepbuild"],
    } ->
    exec { "librealsense-install":
        user        => "mav",
        timeout     => 0,
        command     => "/usr/bin/make install >/srv/maverick/var/log/build/librealsense.install.out 2>&1",
        cwd         => "/srv/maverick/var/build/librealsense/build",
        creates     => "/srv/maverick/software/librealsense/lib/librealsense.so",
    } ->
    
    # Install and activate udev rules
    exec { "librealsense-cp-udevbin":
        command     => "/bin/cp /srv/maverick/var/build/librealsense/config/usb-R200* /usr/local/bin",
        creates     => "/usr/local/bin/usb-R200-in",
    } ->
    exec { "librealsense-cp-udev":
        command     => "/bin/cp /srv/maverick/var/build/librealsense/config/99-realsense-libusb.rules /etc/udev/rules.d",
        creates     => "/etc/udev/rules.d/99-realsense-libusb.rules",
        notify      => Exec["librealsense-udev-control"],
    } ->
    exec { "librealsense-udev-control":
        command         => "/sbin/udevadm control --reload-rules && /sbin/udevadm trigger",
        refreshonly     => true
    }
    
    # Clone examples source from github
    file { "/srv/maverick/code/realsense":
        ensure          => directory,
        owner           => mav,
        group           => mav,
        mode            => "755",
    } ->
    oncevcsrepo { "git-realsense-realsense_samples":
        gitsource   => "https://github.com/IntelRealSense/realsense_samples.git",
        dest        => "/srv/maverick/code/realsense/samples",
    }
    # This doesn't work, for now
    if 1 == 2 {
        exec { "realsense-samples-prepbuild":
            user        => "mav",
            timeout     => 0,
            environment => ["LD_LIBRARY_PATH=/srv/maverick/software/opencv/lib", "PATH=/srv/maverick/software/opencv/bin:/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/sbin", "CMAKE_PREFIX_PATH=/srv/maverick/software/opencv"],
            command     => "/usr/bin/cmake .",
            cwd         => "/srv/maverick/code/realsense/samples",
            creates     => "/srv/maverick/code/realsense/samples/Makefile",
        } ->
        exec { "realsense-samples-build":
            user        => "mav",
            timeout     => 0,
            environment => ["CPLUS_INCLUDE_PATH=/srv/maverick/software/librealsense/include:/srv/maverick/software/opencv/include:/srv/maverick/software/realsense-sdk/include", "LIBRARY_PATH=/srv/maverick/software/librealsense/lib:/srv/maverick/software/opencv/lib:/srv/maverick/software/realsense-sdk/lib"],
            command     => "/usr/bin/make -j${::processorcount} >/srv/maverick/var/log/build/realsense-samples.build.out 2>&1",
            cwd         => "/srv/maverick/code/realsense/samples",
            # creates     => "/srv/maverick/var/build/realsense-samples/sdk/src/core/pipeline/librealsense_pipeline.so",
            require     => [ Exec["realsense-samples-prepbuild"], Exec["realsense-sdk-install"] ]
        }
    }
    
    # Clone realsense-sdk
    oncevcsrepo { "git-realsense-realsense_sdk":
        gitsource   => "https://github.com/IntelRealSense/realsense_sdk.git",
        dest        => "/srv/maverick/var/build/realsense-sdk",
    } ->
    # Create build directory
    file { "/srv/maverick/var/build/realsense-sdk/build":
        ensure      => directory,
        owner       => "mav",
        group       => "mav",
        mode        => 755,
    } ->
    exec { "realsense-sdk-prepbuild":
        user        => "mav",
        timeout     => 0,
        environment => ["LD_LIBRARY_PATH=/srv/maverick/software/opencv/lib", "PATH=/srv/maverick/software/opencv/bin:/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/sbin", "CMAKE_PREFIX_PATH=/srv/maverick/software/opencv"],
        command     => "/usr/bin/cmake -DCMAKE_INSTALL_PREFIX=/srv/maverick/software/realsense-sdk -DCMAKE_INSTALL_RPATH=/srv/maverick/software/realsense-sdk/lib:/srv/maverick/software/librealsense/lib ..",
        cwd         => "/srv/maverick/var/build/realsense-sdk/build",
        creates     => "/srv/maverick/var/build/realsense-sdk/build/Makefile",
        require     => [ File["/srv/maverick/var/build/realsense-sdk/build"], Package["liblz4-dev"], Package["liblog4cxx-dev"] ], # ensure we have all the dependencies satisfied
    } ->
    exec { "realsense-sdk-build":
        user        => "mav",
        timeout     => 0,
        environment => ["CPLUS_INCLUDE_PATH=/srv/maverick/software/librealsense/include:/srv/maverick/software/opencv/include", "LIBRARY_PATH=/srv/maverick/software/librealsense/lib:/srv/maverick/software/opencv/lib"],
        command     => "/usr/bin/make -j${::processorcount} >/srv/maverick/var/log/build/realsense-sdk.build.out 2>&1",
        cwd         => "/srv/maverick/var/build/realsense-sdk/build",
        creates     => "/srv/maverick/var/build/realsense-sdk/build/sdk/src/core/pipeline/librealsense_pipeline.so",
        require     => Exec["realsense-sdk-prepbuild"],
    } ->
    exec { "realsense-sdk-install":
        user        => "mav",
        timeout     => 0,
        command     => "/usr/bin/make install >/srv/maverick/var/log/build/realsense-sdk.install.out 2>&1",
        cwd         => "/srv/maverick/var/build/realsense-sdk/build",
        creates     => "/srv/maverick/software/realsense-sdk/bin/realsense_fps_counter_sample",
    }
    
}