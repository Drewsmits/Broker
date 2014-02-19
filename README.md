# Broker

Broker maps remote resources to local Core Data resources via JSON responses. Using a few simple design standards, you can automatically map JSON attributes to `NSManagedObject` attributes with little effort.

All this fun stuff is done with a few rules.

1. Name your local object attributes the same as remote attributes. For example, if your remote Employee has a "firstName" attribute, don't name your local `NSManagedObject` Employee attribute "first_name". If you want, Broker has the flexibility to map remote names to local ones, but why add the extra code?
2. Use a unique object identifier. Each object you want to persist should have a unique attribute to easily identify it. For example, Employee might have an employeeId. Without this, there isn't a way to safely guarantee one single persisted object.

## Installation

Broker follows standard patterns for iOS static library design.

1. Add the `Broker.xcodeproj` file to your project.
2. Add `Broker` as a target dependency in your targets `Build Phase` tab.
3. Add `libBroker.a` to your targets `Link Binary With Libraries` build phase.
4. Build your app.

Now you should be able to import Broker headers following this pattern.

	#import <Broker/Broker.h>

## Getting Started

Create and configure a new BKController. This should be a long lived object, perhaps stored on your App Delegate or an otherwise appropriate location.

	BKController *controller = [BKController controller];

Register your `NSManagedObject` with the controller in your main Core Data context. What this does is temporarily creates an `Employee` object in your context, traverses all it's properties and relationships, and builds an internal description of what makes an `Employee` object based on `NSEntityDescription` and `NSAttributeDescription`. These descriptions are used to transform JSON into the registered entity.

    [controller.entityMap registerEntityNamed:@"Employee"
                               withPrimaryKey:@"employeeId"
                      andMapNetworkProperties:@"id"
                            toLocalProperties:@"employeeId"
                                    inContext:context];

Note that we are mapping a network property, `id`, to a local property, `employeeId`. Sometimes your API may use different attribute names than what you have in your Core Data. Broker allows you to map between the two.

Now you are ready to process some JSON. By passing in the main `NSManagedObjectContext` into the `BKController`, you are spinning up a child context in which all the work will be done. After the work is done, the context pushes it's changes to the main context. From there, you can choose to either save or not, but this example includes a proper save pattern.

	- (void)processEmployeeJSON:(id)json 
		withController:(BKController *)controller
		 inContext:(NSManagedObjectContext *)context
	{
			__weak NSManagedObjectContext *weakContext = context;
		    [controller processJSONObject:json
                        	asEntityNamed:@"Employee"
                          		inContext:context
                      	  completionBlock:^{
                           [weakContext performBlock:^{
       						 [context save:nil];
    					   }];
                       }];
	}

## Broker and JSON API Design

Broker is built to handle specific styles of JSON responses.

### List of things

Broker **can** process a list of similar things. For example, a JSON response containing a list of Employee objects.

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

Instead, you should return similar objects it as nested lists, which you can process separately.

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

Broker **can** process a nested thing. For example, an Employee with a Department.

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

Broker uses a "primary key" convention to enforce object uniqueness. NSManagedObjects must have a primary key to be registered with Broker. For example, an Employee could have a unique `employeeId` attribute. Once we have a primary key, we can use a simple find or create pattern to guarantee uniqueness. 

**DISCLAIMER**: If you are working with JSON where you might have more than a few thousand entities at once, the find-or-create pattern in it's current form will be slow. I'm working on a faster pattern.

## Getting Started

## Installation


