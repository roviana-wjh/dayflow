package main

import (
	"database/sql"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	_ "modernc.org/sqlite"
)

type StudyRecord struct {
	ID              int64     `json:"id"`
	Title           string    `json:"title"`
	Content         string    `json:"content"`
	DurationMinutes int       `json:"duration_minutes"`
	CreatedAt       time.Time `json:"created_at"`
}
type MoodRecord struct {
	ID         int64     `json:"id"`
	MoodType   string    `json:"mood_type"`
	Note       string    `json:"note"`
	RecordedAt time.Time `json:"recorded_at"`
}

func main() {
	path := os.Getenv("DAYFLOW_DB")
	if path == "" {
		path = "dayflow.db"
	}
	db, err := sql.Open("sqlite", path)
	if err != nil {
		panic(err)
	}
	defer db.Close()
	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS study_records (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, content TEXT, duration_minutes INTEGER NOT NULL, created_at TEXT NOT NULL); CREATE TABLE IF NOT EXISTS mood_records (id INTEGER PRIMARY KEY AUTOINCREMENT, mood_type TEXT NOT NULL, note TEXT, recorded_at TEXT NOT NULL);`)
	if err != nil {
		panic(err)
	}
	r := gin.Default()
	r.GET("/health", func(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"status": "ok"}) })
	r.GET("/api/study/records", func(c *gin.Context) {
		rows, err := db.Query(`SELECT id,title,content,duration_minutes,created_at FROM study_records ORDER BY created_at DESC`)
		if err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		defer rows.Close()
		out := []StudyRecord{}
		for rows.Next() {
			var x StudyRecord
			var created string
			if rows.Scan(&x.ID, &x.Title, &x.Content, &x.DurationMinutes, &created) == nil {
				x.CreatedAt, _ = time.Parse(time.RFC3339, created)
				out = append(out, x)
			}
		}
		c.JSON(200, out)
	})
	r.POST("/api/study/records", func(c *gin.Context) {
		var x StudyRecord
		if c.BindJSON(&x) != nil || x.Title == "" {
			c.JSON(400, gin.H{"error": "title is required"})
			return
		}
		now := time.Now().UTC()
		res, err := db.Exec(`INSERT INTO study_records(title,content,duration_minutes,created_at) VALUES(?,?,?,?)`, x.Title, x.Content, x.DurationMinutes, now.Format(time.RFC3339))
		if err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		x.ID, _ = res.LastInsertId()
		x.CreatedAt = now
		c.JSON(201, x)
	})
	r.GET("/api/moods", func(c *gin.Context) {
		rows, err := db.Query(`SELECT id,mood_type,note,recorded_at FROM mood_records ORDER BY recorded_at DESC`)
		if err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		defer rows.Close()
		out := []MoodRecord{}
		for rows.Next() {
			var x MoodRecord
			var recorded string
			if rows.Scan(&x.ID, &x.MoodType, &x.Note, &recorded) == nil {
				x.RecordedAt, _ = time.Parse(time.RFC3339, recorded)
				out = append(out, x)
			}
		}
		c.JSON(200, out)
	})
	r.POST("/api/moods", func(c *gin.Context) {
		var x MoodRecord
		if c.BindJSON(&x) != nil || x.MoodType == "" {
			c.JSON(400, gin.H{"error": "mood_type is required"})
			return
		}
		now := time.Now().UTC()
		res, err := db.Exec(`INSERT INTO mood_records(mood_type,note,recorded_at) VALUES(?,?,?)`, x.MoodType, x.Note, now.Format(time.RFC3339))
		if err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		x.ID, _ = res.LastInsertId()
		x.RecordedAt = now
		c.JSON(201, x)
	})
	_ = r.Run(":8080")
}
