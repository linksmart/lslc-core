package validator

import "strings"

// Returns true if authorization rules are specified
func (c *Conf) Authorization() bool {
	return len(c.AuthorizationRules) > 0
}

// Authorized checks whether a user/group is authorized to access resource using a specific method
func (c *Conf) Authorized(resource, method, user, group string) bool {
	// Create a tree of paths
	// e.g. parses /path1/path2/path3 to [/path1/path2/path3 /path1/path2 /path1]
	// e.g. parses / to [/]
	resource_split := strings.Split(resource, "/")
	resource_split = resource_split[1:len(resource_split)] // truncate the first slash
	var resource_tree []string
	// construct tree from longest to shortest (/path1) path
	for i := len(resource_split); i >= 1; i-- {
		resource_tree = append(resource_tree, "/"+strings.Join(resource_split[0:i], "/"))
	}
	//fmt.Println(len(resource_split), resource_split)
	//fmt.Println(len(resource_tree), resource_tree)

	// Check whether a is in slice
	inSlice := func(a string, slice []string) bool {
		for _, b := range slice {
			if b == a {
				return true
			}
		}
		return false
	}

	for _, rule := range c.AuthorizationRules {
		for _, res := range resource_tree {
			// Return true if user or group matches a rule
			if inSlice(res, rule.Resources) && inSlice(method, rule.Methods) &&
				(inSlice(user, rule.Users) || inSlice(group, rule.Groups)) {
				return true
			}
		}
	}
	return false
}
