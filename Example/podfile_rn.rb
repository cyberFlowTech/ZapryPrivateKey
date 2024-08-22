#
#def installReactNativeSdk()
#    node_module_pod_file = "../ReactCode/node_modules/react-native/scripts/react_native_pods.rb"
#    
#    if File.exist?(node_module_pod_file)
#    else
#    end
#end

def rnConfig()
    node_module_pod_file = "./node_modules/react-native/scripts/react_native_pods.rb"
    changeRNPath(node_module_pod_file)
end

    
def changeRNPath(node_module_pod_file)
    configStr = ""
    File.open(node_module_pod_file, "r+") {|f|
        configStr = f.read.gsub(/..\/node_modules/, "../node_modules")
    }
    File.open(node_module_pod_file, "w") {|f|
        f.write configStr
    }
end
    
    
