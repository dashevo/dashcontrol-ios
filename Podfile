platform :ios, '10.0'

inhibit_all_warnings!

def app_pods
    pod 'DashSync', :path => '../DashSync/'
    pod 'SDWebImage', '4.3.3'
    pod 'MBCircularProgressBar', '0.3.5'
    pod 'MBProgressHUD', '1.1.0'
    pod 'DeluxeInjection', '0.8.6'
    pod 'KVO-MVVM', '0.5.1'
    pod 'UIViewController-KeyboardAdditions', '1.2.1'
    pod 'Godzippa', '2.0.0'
    
    pod 'SimulatorStatusMagic', :configurations => ['Debug']
end

target 'DashControl' do
  app_pods
end

target 'DashControlTests' do
    app_pods
end
