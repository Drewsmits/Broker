# Broker

**Broker is currently undergoing some changes. Look for a release for the next stable version**

***

Broker maps remote resources to local Core Data resources via JSON responses. Using a few simple design standards, you can automatically map JSON attributes to NSManagedObject attributes with one line of code.

All this fun stuff is done with a few rules.

1. Name your local object attributes the same as remote attributes. For example, if your remote Employee has a "firstName" attribute, don't name your local NSManagedObject Employee attribute "first_name". You can map a remote to a local attribute, but it's extra code.
2. Use a unique identifier. Each object you want to persist should have a unique attribute to easily identify it. For example, Employee might have an employeeId. Without this, there isn't a way to safely gaurantee one single persisted object.

## Broker and JSON API Design

Broker is built to handle specific styles of JSON responses. Certain types of responses are not handled in order to keep the project simple.

### List of things

Broker **can** process a list of similar things. In this case our JSON is a list of Employees.

	[
	    {
	        "name": "Andrew",
	        "department": "Engineering",
	        "employeeId": 1
	    },
	    {
	        "name": "Sarah",
	        "department": "Engineering",
	        "employeeId": 2
	    },
	    {
	        "name": "Steve",
	        "department": "Marketing",
	        "employeeId": 3
	    }
	]
	
Broker **cannot** process a mixed list of things, like Employee's and Departments.

	[
	    {
	        "name": "Andrew",
	        "department": "Engineering",
	        "employeeId": 1
	    },
	    {
	        "name": "Engineering",
	        "departmentId": 2
	    },
	]

Instead, you should return similar objects it as nested lists.

	[
	    {
	        "employees": [
	            {
	                "name": "Andrew",
	                "department": "Engineering",
	                "employeeId": 1
	            }
	        ]
	    },
	    {
	        "departments": [
	            {
	                "name": "Engineering",
	                "departmentId": 2
	            }
	        ]
	    }
	]

### A Single Thing

Broker **can** process a single thing. For example, a single Employee.

	{
	    "name": "Andrew",
	    "department": "Engineering",
	    "employeeId": 1
	}
	
### A Nested Thing on a Thing

Broker **can** process a nested thing. For example, an Employee with a department.

	{
	    "name": "Andrew",
	    "employeeId": 1,
	    "department": {
	        "name": "Engineering",
	        "departmentId": 1
	    }
	}
	
### A Nested List of Things on a Thing

Broker **can** process a nested list of things on a thing. For example, a Department with a list of Employees.

	{
	    "name": "Engineering",
	    "departmentId": 1,
	    "employees": [
	        {
	            "name": "Andrew",
	            "departmentId": 1
	        },
	        {
	            "name": "Sarah",
	            "employeeId": 2
	        }
	    ]
	}

### Unique Objects

Broker uses a "primaryKey" convention to enforce object uniqueness. NSManagedObjects must have a primary key to be registered with Broker. For example, an Employee could have a unique `employeeId` attribute. Once we have a primary key, we can use a simple find or create pattern to guarantee uniqueness. 

**DISCLAIMER**: If you are working with JSON where you might have more than a few thousand entities at once, the find-or-create pattern in it's current form will be slow. I'm working on a faster pattern.

## Getting Started

Here is a quick guide to getting up and running.

### Register NSManagedObjects with Broker


