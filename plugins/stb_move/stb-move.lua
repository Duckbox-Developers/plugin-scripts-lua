-- The Tuxbox Copyright
--
-- Copyright 2018 The Tuxbox Project. All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without modification, 
-- are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice, this list
-- of conditions and the following disclaimer. Redistributions in binary form must
-- reproduce the above copyright notice, this list of conditions and the following
-- disclaimer in the documentation and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS`` AND ANY EXPRESS OR IMPLIED
-- WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
-- AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
-- HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-- The views and conclusions contained in the software and documentation are those of the
-- authors and should not be interpreted as representing official policies, either expressed
-- or implied, of the Tuxbox Project.

caption = "STB-Move"

devbase = "/dev/mmcblk0p"
bootfile = "/boot/STARTUP"

local posix = require "posix"
n = neutrino()
fh = filehelpers.new()

locale = {}
locale["deutsch"] = {
	current_boot_partition = "Die aktuelle Startpartition ist: ",
	choose_source = "\n\nBitte die Quell-Partition auswählen",
	choose_destination = "\n\nBitte die Zielpartition auswählen",
	copy_from = "Soll die Image Sicherung der Partition ",
	copy_to = " in die Sicherung der Partition ",
	copy_to_append = " kopiert werden?",
	is_getting_copied = "Sicherung wird kopiert \n\nBitte warten...",
	copy_successful = "Sicherung wurde erfolgreich kopiert",

}
locale["english"] = {
	current_boot_partition = "The current start partition is: ",
	choose_source = "\n\nPlease choose the source partition",
	choose_destination = "\n\nPlease choose the destination partition",
	copy_from = "Should the image backup of partition ",
	copy_to = " be copied to backup of partition ",
	copy_to_append = "",
       	is_getting_copied = "Backup is getting copied \n\nPlease stand by...",
	copy_successful = " \n\nBackup was copied successful",
}

function sleep (a) 
    local sec = tonumber(os.clock() + a); 
    while (os.clock() < sec) do 
    end 
end

function basename(str)
        local name = string.gsub(str, "(.*/)(.*)", "%2")
        return name
end

function get_imagename(root)
        local glob = require "posix".glob
        for _, j in pairs(glob('/boot/*', 0)) do
                for line in io.lines(j) do
                        if (j ~= bootfile) then
                                if line:match(devbase .. root) then
                                        imagename = basename(j)
                                end
                        end
                end
        end
        return imagename
end

neutrino_conf = configfile.new()
neutrino_conf:loadConfig("/etc/neutrino/config/neutrino.conf")
lang = neutrino_conf:getString("language", "english")
if locale[lang] == nil then
	lang = "english"
end
timing_menu = neutrino_conf:getString("timing.menu", "0")

for line in io.lines(bootfile) do
        i, j = string.find(line, devbase)
        current_root = tonumber(string.sub(line,j+1,j+2))
end

function get_source_partition ()
	chooser_dx = n:scale2Res(600)
	chooser_dy = n:scale2Res(200)
	chooser_x = SCREEN.OFF_X + (((SCREEN.END_X - SCREEN.OFF_X) - chooser_dx) / 2)
	chooser_y = SCREEN.OFF_Y + (((SCREEN.END_Y - SCREEN.OFF_Y) - chooser_dy) / 2)

	chooser = cwindow.new {
       		x = chooser_x,
       		y = chooser_y,
       		dx = chooser_dx,
       		dy = chooser_dy,
       		title = caption,
       		icon = "settings",
       		has_shadow = true,
		btnRed = get_imagename(3),
		btnGreen = get_imagename(5),
		btnYellow = get_imagename(7),
		btnBlue = get_imagename(9) }
	chooser_text = ctext.new {
       		parent = chooser,
       		x = OFFSET.INNER_MID,
       		y = OFFSET.INNER_SMALL,
       		dx = chooser_dx - 2*OFFSET.INNER_MID,
       		dy = chooser_dy - chooser:headerHeight() - chooser:footerHeight() - 2*OFFSET.INNER_SMALL,
       		text = locale[lang].current_boot_partition .. get_imagename(current_root) .. locale[lang].choose_source,
       		font_text = FONT.MENU,
       		mode = "ALIGN_CENTER" }

	chooser:paint()

	i = 0
	d = 500 -- ms
	t = (timing_menu * 1000) / d
	if t == 0 then
		t = -1 -- no timeout
	end

	colorkey = nil
	repeat
	i = i + 1
	msg, data = n:GetInput(d)

	if (msg == RC['red']) then
		source_partition = 1
		source_root = 3
		colorkey = true
	elseif (msg == RC['green']) then
		source_partition = 2
		source_root =5
		colorkey = true
	elseif (msg == RC['yellow']) then
		source_partition = 3
		source_root = 7
		colorkey = true
	elseif (msg == RC['blue']) then
		source_partition = 4
		source_root = 9
		colorkey = true
	end

	until msg == RC['home'] or colorkey or i == t

	chooser:hide()
end

function get_destination_partition ()
        chooser_dx = n:scale2Res(600)
        chooser_dy = n:scale2Res(200)
        chooser_x = SCREEN.OFF_X + (((SCREEN.END_X - SCREEN.OFF_X) - chooser_dx) / 2)
        chooser_y = SCREEN.OFF_Y + (((SCREEN.END_Y - SCREEN.OFF_Y) - chooser_dy) / 2)

        chooser = cwindow.new {
                x = chooser_x,
                y = chooser_y,
                dx = chooser_dx,
                dy = chooser_dy,
                title = caption,
                icon = "settings",
                has_shadow = true,
                btnRed = get_imagename(3),
                btnGreen = get_imagename(5),
                btnYellow = get_imagename(7),
                btnBlue = get_imagename(9) }
        chooser_text = ctext.new {
                parent = chooser,
                x = OFFSET.INNER_MID,
                y = OFFSET.INNER_SMALL,
                dx = chooser_dx - 2*OFFSET.INNER_MID,
                dy = chooser_dy - chooser:headerHeight() - chooser:footerHeight() - 2*OFFSET.INNER_SMALL,
                text = locale[lang].current_boot_partition .. get_imagename(current_root) .. locale[lang].choose_destination,
                font_text = FONT.MENU,
                mode = "ALIGN_CENTER" }

       	chooser:paint()

       	i = 0
       	d = 500 -- ms
       	t = (timing_menu * 1000) / d
       	if t == 0 then
               	t = -1 -- no timeout
       	end

       	colorkey = nil
       	repeat
       	i = i + 1
       	msg, data = n:GetInput(d)

       	if (msg == RC['red']) then
               	destination_partition = 1
		dest_root = 3
               	colorkey = true
       	elseif (msg == RC['green']) then
               	destination_partition = 2
		dest_root = 5
               	colorkey = true
       	elseif (msg == RC['yellow']) then
               	destination_partition = 3
		dest_root = 7
               	colorkey = true
       	elseif (msg == RC['blue']) then
               	destination_partition = 4
		dest_root = 9
               	colorkey = true
       	end

       	until msg == RC['home'] or colorkey or i == t

       	chooser:hide()
end

function do_copy_image ()
       	res = messagebox.exec {
       	title = caption,
       	icon = "settings",
       	text = locale[lang].copy_from .. get_imagename(source_root) .. locale[lang].copy_to .. get_imagename(dest_root) .. locale[lang].copy_to_append,
       	timeout = 0,
       	buttons={ "yes", "no" }
       	}
       	if res == "yes" then
               	local a,b,c = os.execute("mountpoint -q /media/hdd")
               	if (c == 0) then
                       	device = "hdd"
               	else
                       	device = "usb"
               	end

        	local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].is_getting_copied };
                ret:paint()

		local file = assert(io.popen("cp -rf /media/" .. device .. "/service/image/backup/partition" .. source_partition .. "/* /media/" .. device .. "/service/image/backup/partition" .. destination_partition))
		local output = file:read('*all')
		file:close()
		ret:hide()
	       	local success = hintbox.new { title = caption, icon = "settings", text = locale[lang].copy_successful };
       		success:paint()
       		sleep (3)
       		success:hide()
       		return
	end
end

get_source_partition()
if colorkey then
	get_destination_partition()
end

if colorkey then
	do_copy_image()
end
