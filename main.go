package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/PuerkitoBio/goquery"
	_ "github.com/mattn/go-sqlite3"
)

func main() {
	client := &http.Client{}
	req, err := http.NewRequest("GET", "https://www.timeanddate.com/worldclock/timezone/utc", nil)
	if err != nil {
		log.Fatalln(err)
	}

	req.Header.Add("Accept-Language", "en")

	resp, err := client.Do(req)
	if err != nil {
		log.Fatalln(err)
	}

	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		log.Fatalln(err)
	}

	doc, err := goquery.NewDocumentFromReader(resp.Body)
	if err != nil {
		log.Fatalln(err)
	}

	wtime := doc.Find("span#ct").Text()
	wdate := doc.Find("span#ctdat").Text()

	t, err := time.Parse("Monday, 02 January 2006 15:04:05", wdate+" "+wtime)
	if err != nil {
		log.Fatalln(err)
	}

	dk, err := time.LoadLocation("Europe/Berlin")
	if err != nil {
		log.Fatalln(err)
	}

	os.Remove("./db")
	db, err := sql.Open("sqlite3", "./db")
	if err != nil {
		log.Fatalln(err)
	}
	defer db.Close()

	_, err = db.Exec("create table clock (time text);")
	if err != nil {
		log.Fatalln(err)
	}

	tx, err := db.Begin()
	if err != nil {
		log.Fatalln(err)
	}

	stmt, err := tx.Prepare("insert into clock(time) values(?)")
	if err != nil {
		log.Fatalln(err)
	}
	defer stmt.Close()

	stmt.Exec(t)
	stmt.Exec(t.In(dk))
	tx.Commit()

	rows, err := db.Query("select time from clock")
	if err != nil {
		log.Fatalln(err)
	}
	defer rows.Close()
	for rows.Next() {
		var t string
		err = rows.Scan(&t)
		if err != nil {
			log.Fatalln(err)
		}
	}
	err = rows.Err()
	if err != nil {
		log.Fatalln(err)
	}

	fmt.Println("Success!")
}
