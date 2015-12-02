package resource

import (
	"errors"
	"math"
	"reflect"
	"sync"
	"time"
)

type ProxyStorage struct {
	catalogs []RemoteCatalog
	total    int // shared field
	sync.RWMutex
}

func NewProxyStorage(catalogs ...RemoteCatalog) (CatalogStorage, error) {
	if len(catalogs) == 0 {
		return nil, errors.New("ProxyStorage.NewProxyStorage() ERROR: No catalogs given!")
	}

	return &ProxyStorage{
		catalogs: catalogs,
	}, nil
}

type RemoteCatalog struct {
	Endpoint string
	Client   *RemoteCatalogClient
	total    int // shared field
}

// CRUD
func (s *ProxyStorage) get(id string) (Device, error) {
	for _, c := range s.catalogs {
		d, err := c.Client.Get(id)
		if err == nil { // FOUND IT
			return *d, nil
		} else if err != ErrorNotFound {
			logger.Println("ProxyStorage.get() ERROR:", err.Error())
		}
	}
	return Device{}, ErrorNotFound
}

// Utilities

// Calculates ratio-based resource destribution per catalog
func (s *ProxyStorage) calcRatios(perPage int) []int {
	perCatalog := make([]int, len(s.catalogs))
	if s.total == 0 {
		return perCatalog
	}
	sum := 0
	for i := range perCatalog {
		perCatalog[i] = int(math.Ceil(float64(s.catalogs[i].total) * float64(perPage) / float64(s.total)))
		sum += perCatalog[i]
	}

	// modify largest ratio to round the total to perPage
	maxi := 0
	for i, v := range perCatalog {
		if v > perCatalog[maxi] {
			maxi = i
		}
	}
	perCatalog[maxi] -= (sum - perPage)

	return perCatalog
}

func (s *ProxyStorage) getMany(page int, perPage int) ([]Device, int, error) {
	s.Lock()
	defer s.Unlock()

	// init
	if s.total == 0 {
		for i, c := range s.catalogs {
			_, t, err := c.Client.GetMany(1, 1)
			if err != nil {
				logger.Println("ProxyStorage.getMany() ERROR:", err.Error())
				continue
			}
			s.catalogs[i].total = t
			s.total += t
		}
	}

	getMany := func(perCatalog []int) ([]Device, bool) {
		if s.total <= 0 {
			logger.Println("ProxyStorage.getMany() No resources proxied. All catalogs are unreachable or empty.")
			return []Device{}, false
		}

		var devices []Device
		changed := false
		for i, c := range s.catalogs {
			d, t, err := c.Client.GetMany(page, perCatalog[i])
			if err != nil {
				logger.Println("ProxyStorage.getMany() ERROR:", err.Error())
				t = 0
			}

			if s.catalogs[i].total != t {
				logger.Println("ProxyStorage.getMany() Detected changes in catalog", c.Endpoint)
				s.total += (t - s.catalogs[i].total)
				s.catalogs[i].total = t
				changed = true
			}

			if t <= 0 {
				logger.Println("ProxyStorage.getMany() Skipping catalog", c.Endpoint)
				continue
			}

			devices = append(devices, d...)
		}
		return devices, changed
	}
	perCatalog := s.calcRatios(perPage)
	devices, changed := getMany(perCatalog)
	if !changed {
		return devices, s.total, nil
	}

	// Catalog(s) are changed
	perCatalogUpdt := s.calcRatios(perPage)
	if reflect.DeepEqual(perCatalog, perCatalogUpdt) { // rations remain the same
		return devices, s.total, nil
	}

	// Ratios are changed, query again
	devices, _ = getMany(perCatalogUpdt)
	return devices, s.total, nil
}

func (s *ProxyStorage) getResourcesCount() (int, error) {
	total := 0
	for _, c := range s.catalogs {
		_, t, err := c.Client.GetMany(1, 1)
		if err != nil {
			logger.Println("ProxyStorage.getResourcesCount() ERROR:", err.Error())
			continue
		}
		total += t
	}
	return total, nil
}

func (s *ProxyStorage) getResourceById(id string) (Resource, error) {
	for _, c := range s.catalogs {
		r, err := c.Client.GetResource(id)
		if err == nil { // FOUND IT
			return *r, nil
		} else if err != ErrorNotFound {
			logger.Println("ProxyStorage.getResourceById() ERROR:", err.Error())
			continue
		}
	}
	return Resource{}, ErrorNotFound
}

// Path filtering
func (s *ProxyStorage) pathFilterDevice(path, op, value string) (Device, error) {
	for _, c := range s.catalogs {
		d, err := c.Client.FindDevice(path, op, value)
		if err == nil { // FOUND IT
			return *d, nil
		} else if err != ErrorNotFound {
			logger.Println("ProxyStorage.pathFilterDevice() ERROR:", err.Error())
			continue
		}
	}
	return Device{}, ErrorNotFound
}

func (s *ProxyStorage) pathFilterDevices(path, op, value string, page, perPage int) ([]Device, int, error) {
	quotient := perPage / len(s.catalogs)
	remainder := perPage - len(s.catalogs)*quotient
	perCatalog := make([]int, len(s.catalogs))
	for i := range perCatalog {
		perCatalog[i] = quotient
	}
	perCatalog[len(perCatalog)-1] += remainder

	var devices []Device
	var total int = 0
	for i, c := range s.catalogs {
		d, t, err := c.Client.FindDevices(path, op, value, page, perCatalog[i])
		if err != nil {
			logger.Println("ProxyStorage.pathFilterDevices() ERROR:", err.Error())
			continue
		}
		devices = append(devices, d...)
		total += t
	}
	return devices, total, nil
}

func (s *ProxyStorage) pathFilterResource(path, op, value string) (Resource, error) {
	for _, c := range s.catalogs {
		r, err := c.Client.FindResource(path, op, value)
		if err == nil { // FOUND IT
			return *r, nil
		} else if err != ErrorNotFound {
			logger.Println("ProxyStorage.pathFilterResource() ERROR:", err.Error())
			continue
		}
	}
	return Resource{}, ErrorNotFound
}

func (s *ProxyStorage) pathFilterResources(path, op, value string, page, perPage int) ([]Device, int, error) {
	quotient := perPage / len(s.catalogs)
	remainder := perPage - len(s.catalogs)*quotient
	perCatalog := make([]int, len(s.catalogs))
	for i := range perCatalog {
		perCatalog[i] = quotient
	}
	perCatalog[len(perCatalog)-1] += remainder

	var devs []Device
	var total int = 0
	for i, c := range s.catalogs {
		d, t, err := c.Client.FindResources(path, op, value, page, perCatalog[i])
		if err != nil {
			logger.Println("ProxyStorage.pathFilterResources() ERROR:", err.Error())
			continue
		}
		devs = append(devs, d...)
		total += t
	}
	return devs, total, nil
}

func (s *ProxyStorage) Close() error {
	return nil
}

// NOT IMPLEMENTED
func (s *ProxyStorage) add(d Device) error {
	return errors.New("ProxyStorage: Forbidden operation.")
}
func (s *ProxyStorage) update(id string, d Device) error {
	return errors.New("ProxyStorage: Forbidden operation.")
}
func (s *ProxyStorage) delete(id string) error {
	return errors.New("ProxyStorage: Forbidden operation.")
}
func (s *ProxyStorage) getDevicesCount() (int, error) {
	return -1, errors.New("ProxyStorage: Operation not implemented.")
}
func (s *ProxyStorage) cleanExpired(timestamp time.Time) {}
