package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"
)

type ipRateLimiter struct {
	mu       sync.Mutex
	limiters map[string]*clientLimiter
	rate     rate.Limit
	burst    int
}

type clientLimiter struct {
	limiter  *rate.Limiter
	lastSeen time.Time
}

func NewIPRateLimiter(r rate.Limit, b int) *ipRateLimiter {
	i := &ipRateLimiter{
		limiters: make(map[string]*clientLimiter),
		rate:     r,
		burst:    b,
	}

	// Periodically clean up stale client limiters
	go func() {
		for {
			time.Sleep(5 * time.Minute)
			i.mu.Lock()
			for ip, client := range i.limiters {
				if time.Since(client.lastSeen) > 10*time.Minute {
					delete(i.limiters, ip)
				}
			}
			i.mu.Unlock()
		}
	}()

	return i
}

func (i *ipRateLimiter) getLimiter(ip string) *rate.Limiter {
	i.mu.Lock()
	defer i.mu.Unlock()

	client, exists := i.limiters[ip]
	if !exists {
		limiter := rate.NewLimiter(i.rate, i.burst)
		i.limiters[ip] = &clientLimiter{
			limiter:  limiter,
			lastSeen: time.Now(),
		}
		return limiter
	}

	client.lastSeen = time.Now()
	return client.limiter
}

// RateLimit middleware enforces token bucket rate limiting per client IP
func RateLimit(limiter *ipRateLimiter) gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		if !limiter.getLimiter(ip).Allow() {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "RATE_LIMIT_EXCEEDED",
					"message": "Too many requests. Please try again later.",
				},
			})
			return
		}
		c.Next()
	}
}
