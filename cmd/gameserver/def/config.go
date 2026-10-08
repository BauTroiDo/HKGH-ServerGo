package def

import (
	"path/filepath"

	"github.com/rxjh-emu/server/share/conf"
	"github.com/rxjh-emu/server/share/directory"
	"github.com/rxjh-emu/server/share/log"
)

type Config struct {
	PublicIp   string
	Port       int
	MaxUsers   int
	UseLocalIp bool

	ServerType int

	// AutomaticArchive is the reference's GameServer/AutomaticArchive switch
	// (World.cs:645): the original server writes every online character back to the
	// game database on its own timer, and only a server that must not touch the
	// database at all turns it off.
	AutomaticArchive bool

	MasterIp   string
	MasterPort int

	ScriptDirectory string

	// MailSender and MailGreeting are the reference's GameServer/Nguoi_GuiThu and
	// GameServer/DangNhap_TruyenThuNoiDung (World.cs:4573): the name a letter arrives
	// from and its text, with the character's own name standing in for {0}. An empty
	// greeting hands out no letter at all.
	MailSender   string
	MailGreeting string
}

// Attempts to read server configuration file
func (c *Config) Read() {
	log.Info("Reading configuration...")

	var location = directory.Root() + "/cfg/" + GetName() + ".ini"

	// parse configuration file...
	if err := conf.Open(location); err != nil {
		log.Fatal(err.Error())
		return
	}

	// read values from configuration...
	c.PublicIp = conf.GetString("network", "ip", "127.0.0.1")
	c.Port = conf.GetInt("network", "port", 13211) // Legacy V21 port (was 16101)
	c.MaxUsers = conf.GetInt("network", "max_users", 100)
	c.UseLocalIp = conf.GetBool("network", "use_local_ip", false)

	c.ServerType = conf.GetInt("server", "server_type", 0)
	c.AutomaticArchive = conf.GetBool("server", "automatic_archive", true)

	c.MasterIp = conf.GetString("master", "ip", "127.0.0.1")
	c.MasterPort = conf.GetInt("master", "port", 9001)

	c.ScriptDirectory = scriptDirectory(directory.Root(), conf.GetString("script", "directory", ""))

	c.MailSender = conf.GetString("server", "Nguoi_GuiThu", "Sáng Tạo Ý Giang Hồ")
	c.MailGreeting = conf.GetString("server", "DangNhap_TruyenThuNoiDung",
		"Chào mừng {0} gia nhập HKGH. Máy chủ ổn định lâu dài, công bằng, đáng tin cậy!")
}

// scriptDirectory resolves the ini's [script] folder the way the ini path above is
// resolved: a bare folder belongs to the server's own root, so the binary finds its
// scripts whether it was started from bin or from the repository. The reference's own
// path is Application.StartupPath + "\Script" (ScriptClass.cs:150), which is the same
// answer for a server run out of its bin directory. An empty folder means no scripts at
// all, and an absolute one is the operator's own answer and is not moved.
func scriptDirectory(root, configured string) string {
	if configured == "" || filepath.IsAbs(configured) {
		return configured
	}
	return filepath.Join(root, filepath.FromSlash(configured))
}
