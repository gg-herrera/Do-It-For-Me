import os
import threading
while True:
    try:
        from termcolor import colored
        import customtkinter as custk
        from customtkinter import CTkButton, CTkCheckBox, CTkEntry, CTkLabel, CTkRadioButton, CTkSwitch, CTkInputDialog, CTkProgressBar, CTkTextbox
        import subprocess
        import shutil
        break
    except ImportError as e:
        import subprocess
        subprocess.run(['uv', 'pip', 'install', e.name])
        continue

# Variables globales
checkboxes_list = []
app = None
scroll_frame = None
status_label = None
progress_bar = None
installing = False
output_window = None
output_textbox = None

UnsortedAppDB = {
    "Brave": "choco install brave -y",
    "Chrome": "choco install googlechrome -y",
    "Firefox": "choco install firefox -y",
    "Opera": "choco install opera -y",
    "OperaGX": "choco install operagx -y",
    "EpicGames": "choco install epicgameslauncher -y",
    "Groove": "choco install groove -y",
    "Steam": "choco install steam -y",
    "Discord": "choco install discord -y",
    "Zoom": "choco install zoom -y",
    "VLC": "choco install vlc -y",
    "Winrar": "choco install winrar -y",
    "WPSOffice": "choco install wps-office -y",
    "LibreOffice": "choco install libreoffice-fresh -y",
    "BleachBit": "choco install bleachbit -y",
    "Avast": "choco install avastfreeantivirus -y",
    "ProtonVPN": "choco install protonvpn -y",
    "Spotify": "choco install spotify -y",
    "Vscode": "choco install vscode -y",
    "Python": "choco install python -y",
    "NodeJS": "choco install nodejs -y",
    "Git": "choco install git -y",
    "Slack": "choco install slack -y",
    "Docker": "choco install docker-desktop -y",
    "OneDrive": "choco install onedrive -y",
    "OBSStudio": "choco install obs-studio -y",
    "VirtualBox": "choco install virtualbox -y",
    "Adobe Acrobat Reader": "choco install adobereader -y",
    "Gimp": "choco install gimp -y",
    "Krita": "choco install krita -y",
    "Audacity": "choco install audacity -y",
    "Inkscape": "choco install inkscape -y",
    "7zip": "choco install 7zip -y",
    "Notepad++": "choco install notepadplusplus -y",
    "VisualStudio": "choco install visualstudio2019community -y",
    "Postman": "choco install postman -y",
    "FileZilla": "choco install filezilla -y",
    "PuTTY": "choco install putty -y",
    "Rust": "choco install rust -y",
    "Java": "choco install javaruntime -y",
    "Go": "choco install golang -y",
    "Ruby": "choco install ruby -y",
    "Eclipse": "choco install eclipse -y",
    "IntelliJIDEA": "choco install intellijidea-community -y",
    "Notion": "choco install notion -y",
    "Telegram": "choco install telegram -y",
    "CCleaner": "choco install ccleaner -y",
    "Microsoft Teams": "choco install microsoft-teams -y",
    "PowerToys": "choco install powertoys -y",
    "Flash Player": "choco install flashplayer -y",
    "Teamviewer": "choco install teamviewer -y",
    "AnyDesk": "choco install anydesk -y",
    "Office365": "choco install office365business -y",
    "SumatraPDF": "choco install sumatrapdf -y",
    "Terminal for Windows": "choco install microsoft-windows-terminal -y",
    "Total Commander": "choco install totalcommander -y"
}

AppDB = dict(sorted(UnsortedAppDB.items()))

def createChecks(mainApp, checkList):
    global checkboxes_list
    checkboxes_list = []
    cbCount = 0
    
    for cb in checkList.keys():
        checkbox = CTkSwitch(mainApp, text=cb)
        column = 2 + ((cbCount // 10) * 2)
        row = cbCount % 10
        checkbox.grid(column=column, row=row, pady=20, padx=10, sticky="w")
        cbCount += 1
        checkboxes_list.append(checkbox)
    
    return checkboxes_list

def handle_search(search_text):
    global checkboxes_list
    search_text = search_text.lower().strip()
    
    for checkbox in checkboxes_list:
        app_name = checkbox.cget("text").lower()
        if search_text == "" or search_text in app_name:
            checkbox.grid()
        else:
            checkbox.grid_remove()

def select_all():
    global checkboxes_list, status_label
    for checkbox in checkboxes_list:
        checkbox.select()
    update_status(f"Seleccionadas {len(checkboxes_list)} aplicaciones", "cyan")

def deselect_all():
    global checkboxes_list
    for checkbox in checkboxes_list:
        checkbox.deselect()
    update_status("Todas las aplicaciones deseleccionadas", "yellow")

def update_status(message, color="white"):
    global status_label
    if status_label:
        status_label.configure(text=message, text_color=color)

def create_output_window():
    global output_window, output_textbox
    
    output_window = custk.CTkToplevel()
    output_window.title("Instalación en Progreso")
    output_window.geometry("700x400")
    
    title = CTkLabel(output_window, text="Log de Instalación", font=("Arial", 16, "bold"))
    title.pack(pady=10)
    
    output_textbox = CTkTextbox(output_window, width=680, height=320, font=("Consolas", 10))
    output_textbox.pack(pady=5, padx=10)
    
    close_btn = CTkButton(output_window, text="Cerrar", width=120, command=output_window.destroy)
    close_btn.pack(pady=10)

def add_output_log(message):
    global output_textbox
    if output_textbox:
        output_textbox.configure(state="normal")
        output_textbox.insert("end", f"{message}\n")
        output_textbox.see("end")
        output_textbox.configure(state="disabled")

def install_programs():
    global checkboxes_list, installing, AppDB
    
    if installing:
        update_status("Ya hay una instalación en curso...", "red")
        return

    selected_apps = [cb.cget("text") for cb in checkboxes_list if cb.get() == 1]
    
    if not selected_apps:
        update_status("No has seleccionado ninguna aplicación", "red")
        return

    dialog = CTkInputDialog(
        text=f"¿Instalar {len(selected_apps)} aplicación(es)? Escribe 'si' para confirmar",
        title="Confirmar Instalación"
    )
    
    response = dialog.get_input()
    if response is None or response.lower() != 'si':
        update_status("Instalación cancelada", "yellow")
        return

    create_output_window()
    add_output_log("=== Iniciando instalación ===\n")
    
    installing = True
    thread = threading.Thread(target=install_thread, args=(selected_apps,))
    thread.daemon = True
    thread.start()

def install_thread(selected_apps):
    global installing, progress_bar, AppDB
    
    total = len(selected_apps)
    progress_bar.set(0)
    
    for idx, app_name in enumerate(selected_apps, 1):
        command = AppDB.get(app_name)
        if command:
            update_status(f"Instalando {app_name}... ({idx}/{total})", "cyan")
            add_output_log(f"[{idx}/{total}] Instalando {app_name}...")
            
            try:
                result = subprocess.run(
                    command,
                    shell=True,
                    capture_output=True,
                    text=True
                )
                
                if result.returncode == 0:
                    print(colored(f"[+] {app_name} instalado exitosamente", 'green'))
                    add_output_log(f"✓ {app_name} instalado exitosamente\n")
                else:
                    print(colored(f"[-] Error instalando {app_name}", 'red'))
                    add_output_log(f"✗ Error instalando {app_name}\n")
                    
            except Exception as e:
                print(colored(f"[-] Error: {str(e)}", 'red'))
                add_output_log(f"✗ Error: {str(e)}\n")
        
        progress = idx / total
        progress_bar.set(progress)
    
    update_status(f"¡Instalación completada! ({total} aplicaciones)", "green")
    add_output_log("\n=== Instalación completada ===")
    installing = False

def check_chocolatey():
    try:
        result = subprocess.run(['choco', '--version'], capture_output=True, text=True)
        return result.returncode == 0
    except FileNotFoundError:
        return False

def main():
    global app, scroll_frame, status_label, progress_bar, checkboxes_list, AppDB
    
    print()
    print(colored("======================================", 'green').center(shutil.get_terminal_size().columns))
    print(colored("Do It For Me -> All Libraries Imported", 'light_green').center(shutil.get_terminal_size().columns))
    print(colored("======================================", 'green').center(shutil.get_terminal_size().columns))
    
    if not check_chocolatey():
        print(colored("\n[!] ADVERTENCIA: Chocolatey no está instalado.", 'yellow'))
        print(colored("[!] Instala Chocolatey desde: https://chocolatey.org/install", 'yellow'))
    
    app = custk.CTk()
    app.geometry("1000x750")
    app.title("Do It For Me! - Instalador Automatizado")
    
    try:
        app.iconbitmap("./DIFM.ico")
    except:
        pass
    
    custk.set_appearance_mode("dark")
    custk.set_default_color_theme("dark-blue")
    app.resizable(False, False)
    
    title_label = CTkLabel(app, text="Do It For Me! 🚀", font=("Arial", 28, "bold"), text_color="cyan")
    title_label.pack(pady=15)
    
    search_frame = custk.CTkFrame(app, fg_color="transparent")
    search_frame.pack(pady=10)
    
    search_input = CTkEntry(search_frame, placeholder_text='Buscar aplicación...', width=300, height=35)
    search_input.pack(side="left", padx=5)
    
    search_button = CTkButton(
        search_frame, 
        text="🔍 Buscar",
        width=100,
        height=35,
        command=lambda: handle_search(search_input.get())
    )
    search_button.pack(side="left", padx=5)
    
    selection_frame = custk.CTkFrame(app, fg_color="transparent")
    selection_frame.pack(pady=5)
    
    select_all_btn = CTkButton(
        selection_frame,
        text="✓ Seleccionar Todo",
        width=150,
        height=35,
        command=select_all
    )
    select_all_btn.pack(side="left", padx=5)
    
    deselect_all_btn = CTkButton(
        selection_frame,
        text="✗ Deseleccionar Todo",
        width=150,
        height=35,
        command=deselect_all
    )
    deselect_all_btn.pack(side="left", padx=5)
    
    install_button = CTkButton(
        app,
        text="💾 Instalar Seleccionadas",
        width=300,
        height=45,
        font=("Arial", 14, "bold"),
        command=install_programs,
        fg_color="#2ecc71",
        hover_color="#27ae60"
    )
    install_button.pack(pady=15)
    
    scroll_frame = custk.CTkScrollableFrame(app, width=950, height=500)
    scroll_frame.pack(pady=15, padx=10)
    
    checkboxes_list = createChecks(scroll_frame, AppDB)
    
    progress_bar = CTkProgressBar(app, width=950)
    progress_bar.pack(pady=10)
    progress_bar.set(0)
    
    status_label = CTkLabel(
        app,
        text=f"Listo para instalar. {len(AppDB)} aplicaciones disponibles.",
        font=("Arial", 12)
    )
    status_label.pack(pady=5)
    
    try:
        app.mainloop()
    except KeyboardInterrupt:
        print(colored("\n[-] Keyboard Interrupt detected. Exiting...", 'red'))

if __name__ == "__main__":
    main()