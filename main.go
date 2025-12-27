package main

import (
	"bytes"
	"log"
	"os"
	"os/exec"
	"path"
	"strings"
	"text/template"
)

const (
	ChronydBinPath       = "/usr/local/bin/chronyd"
	ChronydConfigTplPath = "/etc/chrony/chrony.conf.tpl"
	ChronydConfigPath    = "/etc/chrony/chrony.conf"
)

type ChronydConfigTemplate struct {
	NTPServers []string
	HostIP     string
}

func main() {
	ntpServers := os.Getenv("NTP_SERVERS")

	if ntpServers == "" {
		log.Fatal("NTP_SERVERS is empty")
	}

	ntpServersList := strings.Split(ntpServers, ",")

	hostIP := os.Getenv("HOST_IP")
	if hostIP == "" {
		hostIP = "0.0.0.0"
	}

	configTemplate := ChronydConfigTemplate{
		NTPServers: ntpServersList,
		HostIP:     hostIP,
	}

	configBuffer := &bytes.Buffer{}

	err := template.Must(template.New(path.Base(ChronydConfigTplPath)).ParseFiles(ChronydConfigTplPath)).Execute(configBuffer, configTemplate)
	if err != nil {
		log.Fatal(err)
	}
	err = os.WriteFile(ChronydConfigPath, configBuffer.Bytes(), 0600)
	if err != nil {
		log.Fatal(err)
	}

	cmd := exec.Command(ChronydBinPath, "-d", "-s", "-f", ChronydConfigPath)
	cmd.Env = os.Environ()
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	err = cmd.Run()
	if err != nil {
		log.Fatal(err)
	}
}
