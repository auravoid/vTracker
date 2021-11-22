module main

import net.http
import x.json2
import encoding.base64
import os
import toml

const (
        config_location = '$os.home_dir()/.config/vtracker.toml'
)

fn main() {
        println('')
        println('          **********                          **                   ')
        println('         /////**///                          /**                   ')
        println(' **    **    /**     ******  ******    ***** /**  **  *****  ******')
        println('/**   /**    /**    //**//* //////**  **///**/** **  **///**//**//*')
        println('//** /**     /**     /** /   ******* /**  // /****  /******* /** / ')
        println(' //****      /**     /**    **////** /**   **/**/** /**////  /**   ')
        println('  //**       /**    /***   //********//***** /**//**//******/***   ')
        println('   //        //     ///     ////////  /////  //  //  ////// ///    ')
        println('')
        println('Powered by One Tracker and V')

        is_config := toml.parse(config_location) or {
                println('Config file not found! Creating it now...')
                println('')
                new_email := os.input('Enter your email: ')
                println('')
                new_password := os.input('Enter your password: ')
                encoded_password := base64.encode_str('$new_password')
                os.write_file(config_location, "email=\"$new_email\"\npassword=\"$encoded_password\"") or {
                        eprintln('Something went wrong! $err')
                        return
                }
                println('Config location is: $config_location')
                println('Please restart the program')
                return
        }

        email := is_config.value('email').string()
        crypted_password := is_config.value('password').string()

        password := base64.decode_str(crypted_password)
        d := '{"email":"$email","password":"$password"}'
        if auth := http.post('https://api.onetracker.app/auth/token', d) {
                get_login_data := json2.raw_decode(auth.text) or {
                        eprintln('Something went wrong! $err')
                        return
                }
                login_data := get_login_data.as_map()
                session := login_data['session'].as_map()
                token := session['token'].str()

                mut fetch_config := http.FetchConfig{
                        url: 'https://api.onetracker.app/parcels'
                        user_agent: 'vTracker [WIP]'
                }
                fetch_config.header.add_custom('x-api-token', token) or {
                        eprintln('Something went wrong! $err')
                        return
                }

                if prcls := http.fetch(fetch_config) {
                        get_parcel_data := json2.raw_decode(prcls.text) or {
                                eprintln('Something went wrong! $err')
                                return
                        }
                        parcel_data := get_parcel_data.as_map()
                        parcels := parcel_data['parcels'].as_map()

                        println('')
                        println('Your Packages')
                        println('-------------------------')
                        for i, data in parcels {
                                println('')
                                println(parcels['$i'].as_map()['tracking_id'])
                                println(parcels['$i'].as_map()['description'].str())
                                println(parcels['$i'].as_map()['carrier_name'])
                                println('')
                                println(parcels['$i'].as_map()['tracking_status'])
                                println('')
                                println('-------------------------')
                        }
                } else {
                        println(err)
                }
                return
        }
}