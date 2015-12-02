package service

import (
	"errors"
	"strings"
	"time"
)

var ErrorNotFound = errors.New("NotFound")

// Structs

// Service is a service entry in the catalog
type Service struct {
	Id             string                 `json:"id"`
	Type           string                 `json:"type"`
	Name           string                 `json:"name"`
	Description    string                 `json:"description"`
	Meta           map[string]interface{} `json:"meta"`
	Protocols      []Protocol             `json:"protocols"`
	Representation map[string]interface{} `json:"representation"`
	Ttl            int                    `json:"ttl"`
	Created        time.Time              `json:"created"`
	Updated        time.Time              `json:"updated"`
	Expires        *time.Time             `json:"expires"`
}

// Deep copy of the Service
func (self *Service) copy() Service {
	var sc Service

	sc = *self
	proto := make([]Protocol, len(self.Protocols))
	copy(proto, self.Protocols)
	sc.Protocols = proto

	return sc
}

// Validates the Service configuration
func (s *Service) validate() bool {
	if s.Id == "" || len(strings.Split(s.Id, "/")) != 2 || s.Name == "" || s.Ttl == 0 {
		return false
	}
	return true
}

// Checks whether the service can be tunneled in GC
func (s *Service) isGCTunnelable() bool {
	// Until the service discovery in GC is not working properly,
	// we can only tunnel services that never expire (tll == -1)
	if s.Ttl != -1 {
		return false
	}

	v, ok := s.Meta[MetaKeyGCExpose]
	if !ok {
		return false
	}

	// flag should be bool
	e := v.(bool)
	if e == true {
		return true
	}
	return false
}

// Protocol describes the service API
type Protocol struct {
	Type         string                 `json:"type"`
	Endpoint     map[string]interface{} `json:"endpoint"`
	Methods      []string               `json:"methods"`
	ContentTypes []string               `json:"content-types"`
}

// Interfaces

// Storage interface
type CatalogStorage interface {
	// CRUD
	add(s Service) error
	update(id string, s Service) error
	delete(id string) error
	get(id string) (Service, error)

	// Utility functions
	getMany(page, perPage int) ([]Service, int, error)
	getCount() (int, error)
	cleanExpired(ts time.Time)
	Close() error

	// Path filtering
	pathFilterOne(path, op, value string) (Service, error)
	pathFilter(path, op, value string, page, perPage int) ([]Service, int, error)
}

// Listener interface can be used for notification of the catalog updates
// NOTE: Implementations are expected to be thread safe
type Listener interface {
	added(s Service)
	updated(s Service)
	deleted(id string)
}

// Sorted-map data structure based on AVL Tree (go-avltree)
type SortedMap struct {
	key   interface{}
	value interface{}
}

// Operator for Time-type key
func timeKeys(a interface{}, b interface{}) int {
	if a.(SortedMap).key.(time.Time).Before(b.(SortedMap).key.(time.Time)) {
		return -1
	} else if a.(SortedMap).key.(time.Time).After(b.(SortedMap).key.(time.Time)) {
		return 1
	}
	return 0
}
