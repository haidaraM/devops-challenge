import {Component, OnInit} from '@angular/core';
import {HttpClient, HttpErrorResponse} from "@angular/common/http";


interface Config {
    apiUrl: string;
    env: string;
}

interface User {
    id: string;
    name: string;
    address: string;
}

@Component({
    selector: 'app-root',
    templateUrl: './app.component.html',
    styleUrls: ['./app.component.css']
})
export class AppComponent implements OnInit {
    title = 'devops-challenge';
    config!: Config;
    users: User[] = [];
    showUsersText = "Load users from DynamoDB"

    constructor(private httpClient: HttpClient) {

    }

    ngOnInit() {
        this.httpClient.get<Config>("assets/config.json").subscribe(data => {
            this.config = data;
        })
    }

    showUsers($event: MouseEvent) {
        const btnText = this.showUsersText;
        this.showUsersText = "Loading..."
        this.httpClient.get<User[]>(`${this.config.apiUrl}/users`).subscribe(users => {
            this.showUsersText = btnText;
            this.users = users;
        }, ((error: HttpErrorResponse) => {
            console.log(error);
            alert(`Error when fetching users: ${error.status}`);
        }))
    }
}
