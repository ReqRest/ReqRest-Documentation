---
uid: getting_started
---

# Getting Started

## Introduction

This guide is going to teach you how to work with the ReqRest library by showing you, step-by-step,
how an API client can be written with ReqRest.
The client is going to interact with the [JSON Placeholder API](https://jsonplaceholder.typicode.com)
created by [typicode](https://github.com/typicode). JSON Placeholder is an awesome fake REST API
which mocks responses and is thus ideal for demo projects. If you want to learn more about it,
have a look at the documentation [here](https://jsonplaceholder.typicode.com/guide.html).

Towards the end of this article, the API client will be able to interact with the `/todos` and 
`/todos/{id}` endpoints. These endpoints deal with the `TodoItem` resource which looks like this:

```json
{
    "userId": 1,
    "id": 1,
    "title": "Learn about ReqRest",
    "completed": false
}
```

By using the final client, a user will be able to interact with the API using code similar to this:

```csharp
JsonPlaceholderClient client = new JsonPlaceholderClient();

// Get the TodoItem with the ID 1.
var (response, resource) = await client.Todos(1).Get().FetchAsync();
resource.Match(
    item => Console.WriteLine($"Task: {item.Title}."),
    ()   => Console.WriteLine($"Unexpected status code: {response.StatusCode}.")
);

```

> [!NOTE]
> This guide will make use of new language features introduced with C# 8.0, namely Nullable
> Reference Types. If your current development environment doesn't support C# 8.0, simply
> ignore every `?` behind a reference type in the code below.


## Installation and Project Setup 

Create a new console project and reference both the [`ReqRest`](https://www.nuget.org/packages/ReqRest)
and the [`ReqRest.Serializers.NewtonsoftJson`](https://www.nuget.org/packages/ReqRest.Serializers.NewtonsoftJson)
package, for example via:

```bash
dotnet new console -n GettingStarted
dotnet add package ReqRest
dotnet add package ReqRest.Serializers.NewtonsoftJson
```

Afterwards, create the `TodoItem` DTO class which is going to be used in the following code.

```csharp
using Newtonsoft.Json;

public class TodoItem
{
    [JsonProperty("id")]
    public int? Id { get; set; }

    [JsonProperty("userId")]
    public int? UserId { get; set; }

    [JsonProperty("title")]
    public string? Title { get; set; }

    [JsonProperty("completed")]
    public bool? Completed { get; set; }
}
```


## Creating the `JsonPlaceholderClient`

Independent of what API you are wrapping, you will always have to create a class which inherits
from the @"ReqRest.RestClient" class. Such a client is the entry point for creating requests
against the REST API.

Create a new class called `JsonPlaceholderClient`, inherit from the @"ReqRest.RestClient" class
and copy the code below.

```csharp
using System;
using ReqRest;

public sealed class JsonPlaceholderClient : RestClient
{
    private static readonly RestClientConfiguration DefaultConfig = new RestClientConfiguration()
    {
        BaseUrl = new Uri("https://jsonplaceholder.typicode.com"),
    };

    public JsonPlaceholderClient(RestClientConfiguration? configuration = null)
        : base(configuration ?? DefaultConfig) { }
}
```

As you can see, any @"ReqRest.RestClient" must be configured with a @"ReqRest.RestClientConfiguration".
This configuration holds several important values with the most important one being the
@"ReqRest.RestClientConfiguration.BaseUrl". This URL is later on combined with the paths of the
API endpoints, e.g. `"/todos"`.

> [!TIP]
> It is recommended to follow the example above and make the @"ReqRest.RestClientConfiguration"
> an optional constructor parameter so that a user **can** pass in a custom configuration, but
> **doesn't have** to.

By now, the client can already be instantiated, but it cannot really do anything. As a next step,
it will be extended with support for the `/todos` interface, so that code like 
`client.Todos().[...]` becomes possible.


## About REST API Interfaces

ReqRest uses the @"ReqRest.RestInterface" class to group requests to the same endpoint.
At this point, it makes sense to have a look at which requests the JSON Placeholder API supports
for the `TodoItem` resource.

| Endpoint      | HTTP Method | Result       |
|-------------- | ----------- | ------------ |
| `/todos`      | `GET`       | `TodoItem[]` |
|               | `POST`      | `TodoItem`   |
| `/todos/{id}` | `GET`       | `TodoItem`   |
|               | `PUT`       | `TodoItem`   |
|               | `DELETE`    | `{ }`        |

You can see that the `/todos` and `/todos/{id}` endpoints basically form two separate groups with
separate, possible requests.
ReqRest models these two groups via the aforementioned @"ReqRest.RestInterface" class. Each group
gets projected to a single class deriving from @"ReqRest.RestInterface" which then exposes the
methods for creating the different requests which can be made against that interface.

In this case, the two classes will be called `TodosInterface` (for `/todos`, because this interface
deals with multiple items) and `TodoInterface` (for `/todos/{id}`, because this interface deals
with a single item).

If this sounds complicated, don't be afraid! The code following below will help a lot to understand
this API design.


## Creating the `TodosInterface`

Every class inheriting from @"ReqRest.RestInterface" requires at least the following code:

```csharp
using ReqRest;
using ReqRest.Builders;

public sealed class TodosInterface : RestInterface
{
    internal TodosInterface(RestClient restClient)
        : base(restClient) { }

    // Every RestInterface is responsible of building up the URL which is ultimately going 
    protected override UrlBuilder BuildUrl(UrlBuilder baseUrl) =>
        baseUrl / "todos";
}
```

Two things are happening here:

First of all, the `TodosInterface` expects a @"ReqRest.RestClient" instance which immediately gets
passed to the base class. This client is required by the interface, because it needs to read out
certain values from the client's configuration, e.g. the @"ReqRest.RestClientConfiguration.BaseUrl".

In addition, every class inheriting from @"ReqRest.RestInterface" must override the 
@"ReqRest.RestInterface.BuildUrl(ReqRest.Builders.UrlBuilder)" method. This method is used by
ReqRest to build up the final URL for a request against this interface.
As you can see, the `TodosInterface` appends the `"todos"` string to a given `baseUrl`.
In this example, `baseUrl` will always come directly from the `JsonPlaceholderClient` which means
that is is going to be `https://jsonplaceholder.typicode.com`.
The `BuildUrl` method above transforms this URL to `https://jsonplaceholder.typicode.com/todos`.

> [!NOTE]
> The slash in `baseUrl / "todos"` is syntactic sugar replacing the @"ReqRest.Builders.UriBuilderExtensions.AppendPath*"
> method and simply adds the `"todos"` string to the URL's path while taking care of correctly formatting
> the slashes. This works similar to .NET's [Path.Combine(string, string)](xref:System.IO.Path.Combine(System.String,System.String))
> method.

At this point, the `TodosInterface` can be instantiated and thus integrated into the `JsonPlaceholderClient`:

```csharp
using System;
using ReqRest;

public sealed class JsonPlaceholderClient : RestClient
{
    // [...]

    public TodosInterface Todos() =>
        new TodosInterface(this);
}
```

Now you can write code like `new JsonPlaceholderClient().Todos()`, but there is no possibility
to create any requests with this interface (for example via a `Get()` method).
This is going to change now! Add the `Get()` method below to the `TodosInterface`.

```csharp
using System.Collections.Generic;
using ReqRest;
using ReqRest.Builders;
using ReqRest.Serializers.NewtonsoftJson;

public sealed class TodosInterface : RestInterface
{
    // [...]

    public ApiRequest<IList<TodoItem>> Get() =>
        BuildRequest()
            .Get()
            .Receive<IList<TodoItem>>().AsJson(forStatusCodes: 200);
}
```

Again, a lot is happening here, but ideally the code speaks for itself.

`Get()` calls the @"ReqRest.RestInterface.BuildRequest" method and afterwards calls a few methods
to declare that the request uses the `GET` HTTP method and will receive a list of `TodoItem`s 
as JSON if the server sends back a response with the status code `200`.

Don't be afraid to use IntelliSense and Visual Studio to see the documentation of the called
methods above. They will explain in detail what they do exactly.

At this point, the API client is functional for the first time! Go ahead and try it out:

```csharp
public static async Task Main(string[] args)
{
    var client = new JsonPlaceholderClient();
    var response = await client.Todos().Get().FetchResponseAsync();
    var resource = await response.DeserializeResourceAsync();

    // The API may not always return the status code 200.
    // ReqRest automatically does the checking for you and calls the correct method depending on the actual status code.
    resource.Match(
        todoItems => Console.WriteLine($"Received status code 200. There are {todoItems.Count} items!"),
        ()        => Console.WriteLine($"Received an unexpected status code: {response.StatusCode}.")
    );
}
```

In the table above, you can see that there is another request that can be made to the API - the
`POST /todos` request. There is one important difference to the `GET` request above. When making a
`POST` request, it should be possible to pass the data, i.e. the `TodoItem` to the request.

In the code, this can easily done via a parameter. This means that the `TodosInterface` can be
extended like this:

```csharp
using System.Collections.Generic;
using ReqRest;
using ReqRest.Builders;
using ReqRest.Serializers.NewtonsoftJson;

public sealed class TodosInterface : RestInterface
{
    // [...]

    public ApiRequest<TodoItem> Post(TodoItem? todoItem) =>
        BuildRequest()
            .PostJson(todoItem)
            .Receive<TodoItem>().AsJson(forStatusCodes: 201);
}
```

This new method can be used like this:

```csharp
public static async Task Main(string[] args)
{
    var client = new JsonPlaceholderClient();
    var itemToPost = new TodoItem() { Title = "Try out the new POST method!" };
    var (response, resource) = await client.Todos().Post(itemToPost).FetchAsync();

    resource.Match(
        createdItem => Console.WriteLine($"Created the item. It has the ID {createdItem.Id}."),
        ()          => Console.WriteLine($"POSTing failed with status code: {response.StatusCode}.")
    );
}
```

> [!NOTE]
> The `FetchAsync()` method in the example above is nothing else but a shortcut for the following:
>
> ```csharp
> var response = await client.Todos().Post(itemToPost).FetchResponseAsync();
> var resource = await response.DeserializeResponseAsync();
> ```

At this point, the `TodosInterface` is entirely done. It is now possible to create and make every
single request to the `/todos` endpoint using the `JsonPlaceholderClient`!


## Creating the `TodoInterface`

The next interface to be created is the `/todos/{id}` interface for interacting with a single
`TodoItem`.

This works similarly to the creation of the `TodosInterface`, but has a few twists:

```csharp
using ReqRest;
using ReqRest.Builders;
using ReqRest.Serializers.NewtonsoftJson;
using ReqRest.Http;

public sealed class TodoInterface : RestInterface
{
    private int _id;

    internal TodoInterface(int id, RestClient restClient) 
        : base(restClient)
    {
        _id = id;
    }

    protected override UrlBuilder BuildUrl(UrlBuilder baseUrl) =>
        baseUrl / "todos" / $"{_id}";

    public ApiRequest<TodoItem> Get() =>
        BuildRequest()
            .Get()
            .Receive<TodoItem>().AsJson(200);

    public ApiRequest<TodoItem> Put(TodoItem? todoItem) =>
        BuildRequest()
            .PutJson(todoItem)
            .Receive<TodoItem>().AsJson(200);

    // This is a little bit special.
    // The JSON Placeholder API returns an empty object {} when a DELETE request succeeds. 
    //
    // For demonstration purposes, this code interprets this as 'NoContent'.
    // Normally, NoContent should be used when a request returns an empty HTTP content
    // (which is also typical for a DELETE request).
    public ApiRequest<NoContent> Delete() =>
        BuildRequest()
            .Delete()
            .ReceiveNoContent(200);
}
```

There are two specialties in this code - the first one is how the ID gets transported into the
class. This is ideally done via the constructor (you will soon see why) and then storing it as a
field, until it is needed by `BuildUrl`.

Furthermore, the `Delete()` method uses the [ReceiveNoContent](xref:ReqRest.ApiRequest.ReceiveNoContent(ReqRest.Http.StatusCodeRange[]))
method to declare that it receives the special @"ReqRest.Http.NoContent" type. As you can see, there
is no additional method call like `AsJson(...)` here, because it is not necessary to declare
which data format "No Content" has.

> [!NOTE]
> There are also other methods similar to [ReceiveNoContent](xref:ReqRest.ApiRequest.ReceiveNoContent(ReqRest.Http.StatusCodeRange[]))
> available, for example [ReceiveString](xref:ReqRest.ApiRequest.ReceiveString(ReqRest.Http.StatusCodeRange[]))
> or [ReceiveByteArray](xref:ReqRest.ApiRequest.ReceiveByteArray(ReqRest.Http.StatusCodeRange[])).

After creating the `TodoInterface` class, don't forget to add it to the `JsonPlaceholderClient`:

```csharp
using System;
using ReqRest;

public sealed class JsonPlaceholderClient : RestClient
{
    // [...]

    public TodoInterface Todos(int id) =>
        new TodoInterface(id, this);
}
```

Here you can see why the ID should ideally be passed via the constructor - because it allows the
client to just pass it forward when creating the interface instance.

When you have two interfaces which interact with the same resource (and a similar endpoint) like in
this example, it is a good idea to give the two methods the same name by overloading them.
This allows expressive code like this:

```csharp
client.Todos().[...]    // for accessing /todos
client.Todos(123).[...] // for accessing /todos/123
```

As you can see, the methods exposed by the client can be directly mapped to the endpoint, just in a
"more C#-ish" way.


## Using the Client

First of all, congratulations! You have finished your first, fully functional REST API client with
ReqRest! Even though it is not complete yet, you can already use it to interact with the APIs
`TodoItem` resource.

Feel free to go ahead and try it out by making some requests and see how it works.

To show a concrete (and more complex) example of how it can be used, the following code section
displays a way to delete all items with an ID smaller than 10.
This example shows how you can use both ReqRest's response type matching and the plain, old
status code checking. 

```csharp
public static async Task Main(string[] args)
{
    var client = new JsonPlaceholderClient();
    var items = await FetchItemsToUpdate(client);

    foreach (var item in items)
    {
        await DeleteItem(client, item);
    }
}

static async Task<IEnumerable<TodoItem>> FetchItemsToUpdate(JsonPlaceholderClient client)
{
    var resource = await client.Todos().Get().FetchResourceAsync();

    // Let ReqRest do the work of checking what gets returned for which status code.
    // Note that Match(...) supports returning values inside of the functions.
    // The result of the function which ultimately gets called also gets returned by Match(...).
    return resource.Match(
        items => items.Where(item => item.Id < 10),
        ()    => throw new Exception("Failed to fetch any TODOs.")
    );
}

static async Task DeleteItem(JsonPlaceholderClient client, TodoItem item)
{
    var id = item.Id.GetValueOrDefault();
    var response = await client.Todos(id).Delete().FetchResponseAsync();
    
    // The response is nothing else but a wrapper around the System.Net.Http.HttpResponseMessage.
    // As such, we have access to the underlying properties, e.g. the StatusCode.
    if (response.StatusCode != HttpStatusCode.OK)
    {
        throw new Exception($"Failed to delete the item with the ID {id}.");
    }

    // Note:
    // Alternatively to checking the response's status code, you could also
    // use FetchResource like in the method above.
    // This leads to a more functional style and lets ReqRest do the status
    // code checking for you, but it is certainly the more "unusual" style
    // and may be harder to understand in the beginning.
    // The code would look like this:

    var result = await client.Todos(id).Delete().FetchResourceAsync();
    result.Match(
        noContent => { /* All good, deleting worked. */ }, 
        ()        => throw new Exception($"Failed to delete the item with the ID {id}.")
    );

    // Or with an alternative to Match:
    if (!result.TryGetValue(out NoContent _))
    {
        throw new Exception($"Failed to delete the item with the ID {id}.");
    }

    // All in all, ReqRest gives you a lot of options to get your task done.
    // It is up to you to choose which flavor you prefer for which scenario.
}
```


## Next Steps

If you got this far, you should have an overview of what ReqRest is capable of.
If you are still interested in learning more, feel free to check out the guides [here](xref:guides)
or browse the [API documentation](xref:api).
